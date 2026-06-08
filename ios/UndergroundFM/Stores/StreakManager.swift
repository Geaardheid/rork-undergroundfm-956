//
//  StreakManager.swift
//  UndergroundFM
//
//  Tracks the daily-listen streak and drives the celebration overlay.
//  Calls the Supabase RPC `register_daily_listen` when a track finishes,
//  and surfaces a `StreakCelebration` when the streak increments.
//  Android-portable: no iOS-only dependencies in the logic.
//

import Foundation
import Observation

/// A pending streak celebration to present full-screen over the app.
struct StreakCelebration: Identifiable, Equatable {
    let id = UUID()
    let newStreak: Int
    let previousStreak: Int
    /// 7 booleans for ma..zo — which days this week are achieved.
    let weekProgress: [Bool]
}

/// Decoded result of the `register_daily_listen` RPC.
nonisolated struct DailyListenResult: Decodable {
    let currentStreak: Int
    let longestStreak: Int
    let didIncrement: Bool

    enum CodingKeys: String, CodingKey {
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case didIncrement = "did_increment"
    }
}

@Observable
final class StreakManager {
    static let shared = StreakManager()

    var currentStreak: Int = 0
    var longestStreak: Int = 0
    /// Non-nil while a celebration should be shown on screen.
    var pendingCelebration: StreakCelebration?

    /// Guards against double registration for the same track-end event.
    @ObservationIgnored private var isRegistering: Bool = false

    private init() {}

    /// Register that the user listened today. Called once when a track plays to
    /// the end (not on skip). Shows a celebration only when the streak went up.
    func registerDailyListen() async {
        guard !isRegistering else { return }
        guard let token = SessionStore.shared.session?.accessToken else { return }
        isRegistering = true
        defer { isRegistering = false }

        do {
            let result = try await fetchResult(token: token)
            currentStreak = result.currentStreak
            longestStreak = result.longestStreak

            if result.didIncrement {
                pendingCelebration = StreakCelebration(
                    newStreak: result.currentStreak,
                    previousStreak: max(0, result.currentStreak - 1),
                    weekProgress: Self.computeWeekProgress()
                )
            }
        } catch {
            // Silent — a failed streak ping should never disrupt playback.
            #if DEBUG
            print("StreakManager: register_daily_listen failed: \(error)")
            #endif
        }
    }

    func dismissCelebration() {
        pendingCelebration = nil
    }

    /// Calls the RPC and decodes the result, accepting both the array-wrapped
    /// (`RETURNS TABLE`) and single-object (`RETURNS composite`) shapes that
    /// PostgREST can return.
    private func fetchResult(token: String) async throws -> DailyListenResult {
        let sb = SupabaseService.shared
        if let rows = try? await sb.rpcValue(
            [DailyListenResult].self,
            "register_daily_listen",
            params: [:],
            accessToken: token
        ), let first = rows.first {
            return first
        }
        return try await sb.rpcValue(
            DailyListenResult.self,
            "register_daily_listen",
            params: [:],
            accessToken: token
        )
    }

    /// Local week progress with a Monday start: every day up to and including
    /// today is filled. Placeholder until real per-day data is wired in.
    static func computeWeekProgress() -> [Bool] {
        let weekday = Calendar.current.component(.weekday, from: Date()) // 1=Sun..7=Sat
        let mondayIndex = (weekday + 5) % 7                              // 0=Mon..6=Sun
        return (0..<7).map { $0 <= mondayIndex }
    }
}
