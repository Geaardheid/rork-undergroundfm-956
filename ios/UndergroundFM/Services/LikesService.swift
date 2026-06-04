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

    /// Wrapper voor het ophalen van enkel de like-id (bestaat-check).
    private nonisolated struct LikeIdRow: Decodable {
        let id: String
    }

    /// Of de gebruiker deze track heeft geliket.
    func isLiked(trackId: String, userId: String) async throws -> Bool {
        let token = SessionStore.shared.session?.accessToken
        let rows: [LikeIdRow] = try await sb.select(
            LikeIdRow.self,
            from: "likes",
            query: [
                "user_id": "eq.\(userId)",
                "track_id": "eq.\(trackId)",
                "select": "id",
                "limit": "1"
            ],
            accessToken: token
        )
        return !rows.isEmpty
    }

    /// Like een track (idempotent dankzij UNIQUE(user_id, track_id)).
    func like(trackId: String, userId: String) async throws {
        let token = SessionStore.shared.session?.accessToken
        try await sb.insert(
            LikeIdRow.self,
            into: "likes",
            values: ["user_id": userId, "track_id": trackId],
            accessToken: token
        )
    }

    /// Verwijder de like van een track.
    func unlike(trackId: String, userId: String) async throws {
        let token = SessionStore.shared.session?.accessToken
        try await sb.delete(
            table: "likes",
            query: ["user_id": "eq.\(userId)", "track_id": "eq.\(trackId)"],
            accessToken: token
        )
    }
}
