//
//  FollowService.swift
//  UndergroundFM
//
//  Volgen/ontvolgen van artiesten (follows tabel).
//

import Foundation

@MainActor
final class FollowService {
    static let shared = FollowService()
    private let sb = SupabaseService.shared

    private init() {}

    private nonisolated struct FollowRow: Decodable { let id: String }

    /// Volgt de huidige gebruiker deze artiest al?
    func isFollowing(artistId: String, userId: String) async throws -> Bool {
        let token = SessionStore.shared.session?.accessToken
        let rows: [FollowRow] = try await sb.select(
            FollowRow.self,
            from: "follows",
            query: [
                "user_id": "eq.\(userId)",
                "artist_id": "eq.\(artistId)",
                "select": "id",
                "limit": "1"
            ],
            accessToken: token
        )
        return !rows.isEmpty
    }

    func follow(artistId: String, userId: String) async throws {
        guard let token = SessionStore.shared.session?.accessToken else {
            throw SupabaseError.message(L10n.shared.t("errors.unknown"))
        }
        _ = try await sb.insert(
            FollowRow.self,
            into: "follows",
            values: ["user_id": userId, "artist_id": artistId],
            accessToken: token
        )
    }

    func unfollow(artistId: String, userId: String) async throws {
        guard let token = SessionStore.shared.session?.accessToken else {
            throw SupabaseError.message(L10n.shared.t("errors.unknown"))
        }
        try await sb.delete(
            table: "follows",
            query: ["user_id": "eq.\(userId)", "artist_id": "eq.\(artistId)"],
            accessToken: token
        )
    }
}
