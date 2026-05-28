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

    enum CodingKeys: String, CodingKey {
        case id
        case artistName = "artist_name"
    }
}

@MainActor
final class ArtistService {
    static let shared = ArtistService()
    private let sb = SupabaseService.shared

    private init() {}

    /// Maakt een artists-row aan voor de huidige user, update users.role naar 'artist'.
    /// Retourneert de aangemaakte artist name.
    @discardableResult
    func becomeArtist(
        userId: String,
        accessToken: String,
        artistName: String,
        bio: String?,
        genreTags: [String],
        instagramUrl: String?
    ) async throws -> String {
        let trimmedName = artistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw SupabaseError.message(L10n.shared.t("artist.errorNameRequired"))
        }

        var values: [String: Any] = [
            "user_id": userId,
            "artist_name": trimmedName,
            "genre_tags": genreTags,
            "revenue_share_pct": 0.50,
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

        // Update users.role
        try await sb.update(
            table: "users",
            query: ["id": "eq.\(userId)"],
            values: ["role": "artist"],
            accessToken: accessToken
        )

        return inserted.first?.artistName ?? trimmedName
    }
}
