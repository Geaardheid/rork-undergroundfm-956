//
//  ViewTracker.swift
//  UndergroundFM
//
//  Tracks listening sessions and posts view events to Supabase.
//  Called by MusicPlayer on play/pause/skip/background.
//

import Foundation
import UIKit

@Observable
@MainActor
final class ViewTracker {
    static let shared = ViewTracker()

    private var sessionId: String?
    private var trackId: String?
    private var userId: String?
    private var latestTime: TimeInterval = 0
    private var didLogEnd: Bool = false

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Session Lifecycle

    func startSession(track: Track, userId: String) {
        if sessionId != nil {
            endSession()
        }
        sessionId = UUID().uuidString
        trackId = track.id
        self.userId = userId
        latestTime = 0
        didLogEnd = false
    }

    func tick(currentTime: TimeInterval, duration _: TimeInterval) {
        guard sessionId != nil, !didLogEnd else { return }
        latestTime = currentTime
    }

    func endSession() {
        guard let sessionId, let trackId, let userId, !didLogEnd else {
            reset()
            return
        }
        didLogEnd = true

        let player = MusicPlayer.shared
        let duration = player.duration
        let currentTime = latestTime

        guard duration > 0 else {
            reset()
            return
        }

        // Preview-only luisterbeurten van niet-abonnees tellen niet als volledige
        // stream: sla de Supabase-insert over wanneer minder dan 30s is geluisterd.
        if currentTime < 30 && !SubscriptionService.shared.isSubscribed {
            reset()
            return
        }

        let completionPct = min(currentTime / duration, 1.0)
        let weightedScore = Self.calculateWeightedScore(completionPct: completionPct)
        let secondsWatched = Int64(currentTime)

        let sid = sessionId
        let tid = trackId
        let uid = userId

        Task {
            await postViewEvent(
                trackId: tid,
                userId: uid,
                sessionId: sid,
                secondsWatched: secondsWatched,
                completionPct: completionPct,
                weightedScore: weightedScore
            )
        }

        reset()
    }

    // MARK: - Private

    private func reset() {
        sessionId = nil
        trackId = nil
        userId = nil
        latestTime = 0
        didLogEnd = false
    }

    @objc private func appWillResignActive() {
        endSession()
    }

    private static func calculateWeightedScore(completionPct: Double) -> Double {
        switch completionPct {
        case ..<0.1: return 0.1
        case ..<0.5: return 0.5
        case 0.9...: return 1.0
        default:     return 0.5
        }
    }

    private nonisolated func postViewEvent(
        trackId: String,
        userId: String,
        sessionId: String,
        secondsWatched: Int64,
        completionPct: Double,
        weightedScore: Double
    ) async {
        let url = SupabaseConfig.url
        let anonKey = SupabaseConfig.anonKey
        guard !url.isEmpty, !anonKey.isEmpty else { return }

        guard let endpoint = URL(string: "\(url)/rest/v1/view_events") else { return }

        let body: [String: Any] = [
            "track_id": trackId,
            "user_id": userId,
            "session_id": sessionId,
            "seconds_watched": secondsWatched,
            "completion_pct": completionPct,
            "weighted_score": weightedScore,
        ]

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        _ = try? await URLSession.shared.data(for: req)

        // Verhoog daarna de afspeelteller van de track (atomair via RPC).
        await incrementStreamCount(trackId: trackId)
    }

    /// Verhoogt de afspeelteller van de track via de Supabase RPC.
    private nonisolated func incrementStreamCount(trackId: String) async {
        let url = SupabaseConfig.url
        let anonKey = SupabaseConfig.anonKey
        guard !url.isEmpty, !anonKey.isEmpty else { return }
        guard let endpoint = URL(string: "\(url)/rest/v1/rpc/increment_stream_count") else { return }

        let body: [String: Any] = ["track_id_input": trackId]
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        _ = try? await URLSession.shared.data(for: req)
    }
}
