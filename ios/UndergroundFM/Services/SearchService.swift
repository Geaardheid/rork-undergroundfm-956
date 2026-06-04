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
    let users: EmbeddedArtistUser?

    var isFoundingArtist: Bool { users?.isFoundingArtist ?? false }
    var avatarUrl: String? { users?.avatarUrl }

    enum CodingKeys: String, CodingKey {
        case id
        case artistName = "artist_name"
        case genreTags = "genre_tags"
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
                "select": "id,artist_name,genre_tags,users(is_founding_artist,display_name,avatar_url)",
                "artist_name": pattern,
                "order": "artist_name.asc",
                "limit": "20"
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
