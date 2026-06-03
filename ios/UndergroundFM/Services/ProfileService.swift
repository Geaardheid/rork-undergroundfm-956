//
//  ProfileService.swift
//  UndergroundFM
//
//  Artiestenprofiel ophalen/bewerken + eigen tracks beheren (edit/delete).
//

import Foundation

@MainActor
final class ProfileService {
    static let shared = ProfileService()
    private let sb = SupabaseService.shared

    private init() {}

    /// Haal een volledig (publiek) artiestenprofiel op via artist_id.
    func fetchProfile(artistId: String) async throws -> ArtistProfile? {
        let token = SessionStore.shared.session?.accessToken
        let rows: [ArtistProfile] = try await sb.select(
            ArtistProfile.self,
            from: "artists",
            query: [
                "id": "eq.\(artistId)",
                "select": "*,users(is_founding_artist,display_name,avatar_url)",
                "limit": "1"
            ],
            accessToken: token
        )
        return rows.first
    }

    /// Haal tracks van een artiest. `liveOnly` voor publieke weergave.
    func fetchTracks(artistId: String, liveOnly: Bool) async throws -> [Track] {
        let token = SessionStore.shared.session?.accessToken
        var query: [String: String] = [
            "select": "*,artists(artist_name)",
            "artist_id": "eq.\(artistId)",
            "order": "created_at.desc",
            "limit": "100"
        ]
        if liveOnly {
            query["status"] = "eq.live"
        } else {
            query["status"] = "neq.removed"
        }
        return try await sb.select(Track.self, from: "tracks", query: query, accessToken: token)
    }

    /// Werk de bio van de eigen artiest bij (max 280 tekens).
    func updateBio(artistId: String, bio: String) async throws {
        guard let token = SessionStore.shared.session?.accessToken else {
            throw SupabaseError.message(L10n.shared.t("errors.unknown"))
        }
        let trimmed = String(bio.trimmingCharacters(in: .whitespacesAndNewlines).prefix(280))
        try await sb.update(
            table: "artists",
            query: ["id": "eq.\(artistId)"],
            values: ["bio": trimmed],
            accessToken: token
        )
    }

    /// Werk titel + beschrijving van een eigen track bij.
    func updateTrack(trackId: String, title: String, description: String) async throws {
        guard let token = SessionStore.shared.session?.accessToken else {
            throw SupabaseError.message(L10n.shared.t("errors.unknown"))
        }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw SupabaseError.message(L10n.shared.t("errors.required"))
        }
        var values: [String: Any] = ["title": trimmedTitle]
        let trimmedDesc = description.trimmingCharacters(in: .whitespacesAndNewlines)
        values["description"] = trimmedDesc.isEmpty ? NSNull() : trimmedDesc
        try await sb.update(
            table: "tracks",
            query: ["id": "eq.\(trackId)"],
            values: values,
            accessToken: token
        )
    }

    /// Verwijder een eigen track uit de database én bijbehorende storage-bestanden.
    func deleteTrack(_ track: Track) async throws {
        guard let token = SessionStore.shared.session?.accessToken else {
            throw SupabaseError.message(L10n.shared.t("errors.unknown"))
        }
        // Storage opruimen (best-effort — DB blijft leidend).
        for urlStr in [track.audioUrl, track.thumbnailUrl].compactMap({ $0 }) {
            if let path = SupabaseService.storagePath(fromPublicURL: urlStr, bucket: "tracks") {
                try? await sb.deleteFromStorage(bucket: "tracks", path: path, accessToken: token)
            }
        }
        try await sb.delete(
            table: "tracks",
            query: ["id": "eq.\(track.id)"],
            accessToken: token
        )
    }
}
