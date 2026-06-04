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

    /// Upload (of vervang) een videoclip voor een bestaande track en sla de URL op.
    func updateTrackVideo(track: Track, videoData: Data, mimeType: String) async throws -> String {
        guard let token = SessionStore.shared.session?.accessToken else {
            throw SupabaseError.message(L10n.shared.t("errors.unknown"))
        }
        let path = "\(track.artistId)/\(track.id).mp4"
        let videoURL = try await sb.uploadToStorage(
            bucket: "clips",
            path: path,
            data: videoData,
            contentType: mimeType,
            accessToken: token
        )
        try await sb.update(
            table: "tracks",
            query: ["id": "eq.\(track.id)"],
            values: ["video_url": videoURL],
            accessToken: token
        )
        return videoURL
    }

    /// Upload een nieuwe profielfoto naar de `avatars` bucket en sla de URL op in users.
    func updateUserAvatar(userId: String, imageData: Data) async throws -> String {
        guard let token = SessionStore.shared.session?.accessToken else {
            throw SupabaseError.message(L10n.shared.t("errors.unknown"))
        }
        let path = "\(userId)/\(UUID().uuidString).jpg"
        let url = try await sb.uploadToStorage(
            bucket: "avatars",
            path: path,
            data: imageData,
            contentType: "image/jpeg",
            accessToken: token
        )
        try await sb.update(
            table: "users",
            query: ["id": "eq.\(userId)"],
            values: ["avatar_url": url],
            accessToken: token
        )
        return url
    }

    /// Upload een nieuwe profielbanner naar de `banners` bucket en sla de URL op bij de artiest.
    func updateArtistBanner(artistId: String, imageData: Data) async throws -> String {
        guard let token = SessionStore.shared.session?.accessToken else {
            throw SupabaseError.message(L10n.shared.t("errors.unknown"))
        }
        let path = "\(artistId)/\(UUID().uuidString).jpg"
        let url = try await sb.uploadToStorage(
            bucket: "banners",
            path: path,
            data: imageData,
            contentType: "image/jpeg",
            accessToken: token
        )
        try await sb.update(
            table: "artists",
            query: ["id": "eq.\(artistId)"],
            values: ["banner_url": url],
            accessToken: token
        )
        return url
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
        if let videoUrl = track.videoUrl,
           let path = SupabaseService.storagePath(fromPublicURL: videoUrl, bucket: "clips") {
            try? await sb.deleteFromStorage(bucket: "clips", path: path, accessToken: token)
        }
        try await sb.delete(
            table: "tracks",
            query: ["id": "eq.\(track.id)"],
            accessToken: token
        )
    }
}
