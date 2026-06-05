//
//  ArtistService.swift
//  UndergroundFM
//
//  Maak een artist-profiel voor een bestaande, ingelogde gebruiker.
//

import Foundation

nonisolated struct ArtistRow: Decodable {
    let id: String
    let artistName: String?
    let userId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case artistName = "artist_name"
        case userId = "user_id"
    }
}

@MainActor
final class ArtistService {
    static let shared = ArtistService()
    private let sb = SupabaseService.shared

    private init() {}

    /// Zoek het artist_id op voor een gegeven user_id. Retourneert nil als niet gevonden.
    func fetchArtistId(userId: String, accessToken: String) async throws -> String? {
        let rows: [ArtistRow] = try await sb.select(
            ArtistRow.self,
            from: "artists",
            query: ["user_id": "eq.\(userId)", "select": "id", "limit": "1"],
            accessToken: accessToken
        )
        return rows.first?.id
    }

    /// Maakt een artists-row aan voor de huidige user, update users.role naar 'artist'.
    /// Retourneert de aangemaakte artist name.
    @discardableResult
    func becomeArtist(
        userId: String,
        accessToken: String,
        artistName: String,
        bio: String?,
        genreTags: [String],
        instagramUrl: String?,
        inviteCode: String
    ) async throws -> String {
        let trimmedName = artistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw SupabaseError.message(L10n.shared.t("artist.errorNameRequired"))
        }

        // Valideer invite code vóór upgrade — invite-only model afdwingen.
        let code = inviteCode.uppercased().trimmingCharacters(in: .whitespaces)
        let codes: [InviteCodeRow] = try await sb.select(
            InviteCodeRow.self,
            from: "invite_codes",
            query: [
                "code": "eq.\(code)",
                "is_active": "eq.true",
                "select": "*",
                "limit": "1"
            ],
            accessToken: accessToken
        )
        guard let inviteRow = codes.first else {
            throw SupabaseError.message(L10n.shared.t("invite.invalid"))
        }
        if let max = inviteRow.maxUses, let used = inviteRow.useCount, used >= max {
            throw SupabaseError.message(L10n.shared.t("invite.invalid"))
        }

        let isFounding = code.hasPrefix("FOUNDING") || code.hasPrefix("FA")
        let sharePct = isFounding ? 0.60 : 0.50

        var values: [String: Any] = [
            "user_id": userId,
            "artist_name": trimmedName,
            "genre_tags": genreTags,
            "invite_code_used": code,
            "revenue_share_pct": sharePct,
            "verified": false
        ]
        if let bio = bio?.trimmingCharacters(in: .whitespacesAndNewlines), !bio.isEmpty {
            values["bio"] = String(bio.prefix(500))
        }
        if let ig = instagramUrl?.trimmingCharacters(in: .whitespacesAndNewlines), !ig.isEmpty {
            values["instagram_url"] = ig
        }

        let inserted: [ArtistRow] = try await sb.insert(
            ArtistRow.self,
            into: "artists",
            values: values,
            accessToken: accessToken
        )

        // Update users.role + founding flag
        try await sb.update(
            table: "users",
            query: ["id": "eq.\(userId)"],
            values: [
                "role": "artist",
                "is_founding_artist": isFounding
            ],
            accessToken: accessToken
        )

        // Claim de invite code (use count ophogen).
        let newCount = (inviteRow.useCount ?? 0) + 1
        try await sb.update(
            table: "invite_codes",
            query: ["code": "eq.\(code)"],
            values: [
                "used_by": userId,
                "used_at": ISO8601DateFormatter().string(from: Date()),
                "use_count": newCount
            ],
            accessToken: accessToken
        )

        return inserted.first?.artistName ?? trimmedName
    }
}
