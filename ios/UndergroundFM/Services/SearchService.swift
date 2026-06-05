//
//  SearchService.swift
//  UndergroundFM
//
//  Live zoeken op artiesten en tracks via PostgREST ilike.
//

import Foundation

/// Compacte artiest-row voor zoekresultaten (incl. founding badge info).
nonisolated struct ArtistSearchResult: Codable, Identifiable, Hashable {
    let id: String
    let artistName: String
    let genreTags: [String]
    let artistAvatarUrl: String?
    let users: EmbeddedArtistUser?

    var isFoundingArtist: Bool { users?.isFoundingArtist ?? false }
    /// Geef de publieke artiestenkolom voorrang; val terug op de oude users-join voor oude data.
    var avatarUrl: String? { artistAvatarUrl ?? users?.avatarUrl }

    enum CodingKeys: String, CodingKey {
        case id
        case artistName = "artist_name"
        case genreTags = "genre_tags"
        case artistAvatarUrl = "avatar_url"
        case users
    }
}

@MainActor
final class SearchService {
    static let shared = SearchService()
    private let sb = SupabaseService.shared

    private init() {}

    /// Voer beide queries parallel uit en geef de resultaten terug.
    func search(query rawQuery: String) async throws -> (artists: [ArtistSearchResult], tracks: [Track]) {
        let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return ([], []) }

        async let artists = searchArtists(trimmed)
        async let tracks = searchTracks(trimmed)
        return try await (artists, tracks)
    }

    /// Zoek artiesten op naam (ilike).
    func searchArtists(_ term: String) async throws -> [ArtistSearchResult] {
        let pattern = "ilike.*\(escape(term))*"
        return try await sb.select(
            ArtistSearchResult.self,
            from: "artists",
            query: [
                "select": "id,artist_name,genre_tags,avatar_url,users(is_founding_artist,display_name,avatar_url)",
                "artist_name": pattern,
                "order": "artist_name.asc",
                "limit": "20"
            ],
            accessToken: SessionStore.shared.session?.accessToken
        )
    }

    /// Meest beluisterde tracks (globaal) — voor de floating covers in de lege staat.
    func mostPlayed(limit: Int = 5) async throws -> [Track] {
        return try await sb.select(
            Track.self,
            from: "tracks",
            query: [
                "select": "*,artists(artist_name)",
                "status": "eq.live",
                "thumbnail_url": "not.is.null",
                "order": "stream_count.desc.nullslast",
                "limit": "\(limit)"
            ],
            accessToken: SessionStore.shared.session?.accessToken
        )
    }

    /// Recent toegevoegde artiesten (created_at desc) — voor de discover-strook.
    func newArtists(limit: Int = 12) async throws -> [ArtistSearchResult] {
        return try await sb.select(
            ArtistSearchResult.self,
            from: "artists",
            query: [
                "select": "id,artist_name,genre_tags,avatar_url,users(is_founding_artist,display_name,avatar_url)",
                "order": "created_at.desc",
                "limit": "\(limit)"
            ],
            accessToken: SessionStore.shared.session?.accessToken
        )
    }

    /// Recent geüploade live tracks (created_at desc).
    func recentUploads(limit: Int = 12) async throws -> [Track] {
        return try await sb.select(
            Track.self,
            from: "tracks",
            query: [
                "select": "*,artists(artist_name)",
                "status": "eq.live",
                "order": "created_at.desc",
                "limit": "\(limit)"
            ],
            accessToken: SessionStore.shared.session?.accessToken
        )
    }

    /// Zoek live tracks op titel (ilike).
    func searchTracks(_ term: String) async throws -> [Track] {
        let pattern = "ilike.*\(escape(term))*"
        return try await sb.select(
            Track.self,
            from: "tracks",
            query: [
                "select": "*,artists(artist_name)",
                "title": pattern,
                "status": "eq.live",
                "order": "weighted_minutes_total.desc.nullslast",
                "limit": "30"
            ],
            accessToken: SessionStore.shared.session?.accessToken
        )
    }

    /// Ontsnap PostgREST-reserveringstekens in de zoekterm.
    private func escape(_ term: String) -> String {
        term
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: "*", with: "")
    }
}
