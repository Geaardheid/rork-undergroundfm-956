//
//  LikesService.swift
//  UndergroundFM
//
//  Gelikte tracks van de huidige gebruiker ophalen.
//

import Foundation

@MainActor
final class LikesService {
    static let shared = LikesService()
    private let sb = SupabaseService.shared

    private init() {}

    /// Wrapper voor de embedded track join op de likes-tabel.
    private nonisolated struct LikeRow: Decodable {
        let tracks: Track?
    }

    /// Tracks die de gebruiker heeft geliket (nieuwste eerst).
    func fetchLikedTracks(userId: String) async throws -> [Track] {
        let token = SessionStore.shared.session?.accessToken
        let rows: [LikeRow] = try await sb.select(
            LikeRow.self,
            from: "likes",
            query: [
                "user_id": "eq.\(userId)",
                "select": "tracks(*,artists(artist_name))",
                "order": "created_at.desc",
                "limit": "50"
            ],
            accessToken: token
        )
        return rows.compactMap { $0.tracks }
    }
}
