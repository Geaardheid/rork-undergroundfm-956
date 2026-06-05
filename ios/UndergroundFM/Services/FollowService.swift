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

    /// Wrapper voor de embedded artist join op de follows-tabel.
    private nonisolated struct FollowArtistRow: Decodable {
        let artists: ArtistProfile?
    }

    /// Artiesten die de gebruiker volgt (nieuwste eerst).
    func fetchFollowedArtists(userId: String) async throws -> [ArtistProfile] {
        let token = SessionStore.shared.session?.accessToken
        let rows: [FollowArtistRow] = try await sb.select(
            FollowArtistRow.self,
            from: "follows",
            query: [
                "user_id": "eq.\(userId)",
                "select": "artists(*,avatar_url,users(is_founding_artist,display_name,avatar_url))",
                "order": "created_at.desc",
                "limit": "100"
            ],
            accessToken: token
        )
        return rows.compactMap { $0.artists }
    }

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
