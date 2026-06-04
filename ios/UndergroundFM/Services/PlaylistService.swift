//
//  PlaylistService.swift
//  UndergroundFM
//
//  CRUD voor gebruikers-playlists + playlist_tracks.
//

import Foundation

@MainActor
final class PlaylistService {
    static let shared = PlaylistService()
    private let sb = SupabaseService.shared

    private init() {}

    /// Wrapper voor het embedden van track-covers uit playlist_tracks.
    private nonisolated struct PlaylistTrackCoverRow: Decodable {
        let playlistId: String
        let tracks: TrackCover?

        enum CodingKeys: String, CodingKey {
            case playlistId = "playlist_id"
            case tracks
        }
    }

    private nonisolated struct TrackCover: Decodable {
        let thumbnailUrl: String?
        enum CodingKeys: String, CodingKey { case thumbnailUrl = "thumbnail_url" }
    }

    private nonisolated struct PlaylistTrackRow: Decodable {
        let tracks: Track?
    }

    // MARK: - Playlists

    /// Alle playlists van de gebruiker (nieuwste eerst).
    func fetchPlaylists(userId: String) async throws -> [Playlist] {
        let token = SessionStore.shared.session?.accessToken
        return try await sb.select(
            Playlist.self,
            from: "playlists",
            query: [
                "user_id": "eq.\(userId)",
                "select": "*",
                "order": "created_at.desc",
                "limit": "100"
            ],
            accessToken: token
        )
    }

    /// Maak een nieuwe playlist aan. Retourneert de aangemaakte playlist.
    @discardableResult
    func createPlaylist(
        userId: String,
        name: String,
        description: String?,
        isPublic: Bool
    ) async throws -> Playlist {
        guard let token = SessionStore.shared.session?.accessToken else {
            throw SupabaseError.message(L10n.shared.t("errors.unknown"))
        }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw SupabaseError.message(L10n.shared.t("library.nameRequired"))
        }
        var values: [String: Any] = [
            "user_id": userId,
            "name": trimmedName,
            "is_public": isPublic,
            "track_count": 0
        ]
        if let desc = description?.trimmingCharacters(in: .whitespacesAndNewlines), !desc.isEmpty {
            values["description"] = desc
        }
        let rows = try await sb.insert(
            Playlist.self,
            into: "playlists",
            values: values,
            accessToken: token
        )
        guard let created = rows.first else {
            throw SupabaseError.invalidResponse
        }
        return created
    }

    /// Verwijder een playlist (cascade verwijdert playlist_tracks).
    func deletePlaylist(id: String) async throws {
        guard let token = SessionStore.shared.session?.accessToken else {
            throw SupabaseError.message(L10n.shared.t("errors.unknown"))
        }
        try await sb.delete(
            table: "playlists",
            query: ["id": "eq.\(id)"],
            accessToken: token
        )
    }

    // MARK: - Playlist tracks

    /// De tracks in een playlist (volgorde van toevoegen).
    func fetchTracks(playlistId: String) async throws -> [Track] {
        let token = SessionStore.shared.session?.accessToken
        let rows: [PlaylistTrackRow] = try await sb.select(
            PlaylistTrackRow.self,
            from: "playlist_tracks",
            query: [
                "playlist_id": "eq.\(playlistId)",
                "select": "tracks(*,artists(artist_name))",
                "order": "added_at.asc",
                "limit": "200"
            ],
            accessToken: token
        )
        return rows.compactMap { $0.tracks }
    }

    /// De eerste tot 4 cover-URL's van een playlist (voor de collage).
    func fetchCoverUrls(playlistId: String) async throws -> [String] {
        let token = SessionStore.shared.session?.accessToken
        let rows: [PlaylistTrackCoverRow] = try await sb.select(
            PlaylistTrackCoverRow.self,
            from: "playlist_tracks",
            query: [
                "playlist_id": "eq.\(playlistId)",
                "select": "playlist_id,tracks(thumbnail_url)",
                "order": "added_at.asc",
                "limit": "4"
            ],
            accessToken: token
        )
        return rows.compactMap { $0.tracks?.thumbnailUrl }
    }

    /// Voeg een track toe aan een playlist (idempotent via UNIQUE). Werkt track_count bij.
    func addTrack(playlistId: String, trackId: String, currentCount: Int) async throws {
        guard let token = SessionStore.shared.session?.accessToken else {
            throw SupabaseError.message(L10n.shared.t("errors.unknown"))
        }
        _ = try await sb.insert(
            PlaylistTrackRow.self,
            into: "playlist_tracks",
            values: ["playlist_id": playlistId, "track_id": trackId],
            accessToken: token
        )
        try await sb.update(
            table: "playlists",
            query: ["id": "eq.\(playlistId)"],
            values: ["track_count": currentCount + 1],
            accessToken: token
        )
    }
}
