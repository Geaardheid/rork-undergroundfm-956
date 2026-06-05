//
//  TracksService.swift
//  UndergroundFM
//
//  Haalt live tracks op uit Supabase, gefilterd per genre.
//

import Foundation

@MainActor
final class TracksService {
    static let shared = TracksService()
    private let sb = SupabaseService.shared

    private init() {}

    /// Tracks per genre. Joint automatisch artists(artist_name).
    func fetchTracks(genre: String, orderBy: GenreSection.OrderBy, limit: Int = 10) async throws -> [Track] {
        let token = SessionStore.shared.session?.accessToken
        let query: [String: String] = [
            "select": "*,artists(artist_name)",
            "status": "eq.live",
            "genre_tags": "cs.{\(genre)}",
            "order": orderBy.rawValue,
            "limit": "\(limit)"
        ]
        return try await sb.select(Track.self, from: "tracks", query: query, accessToken: token)
    }

    /// Eén track ophalen op id (voor deep links naar een gedeelde track).
    func fetchTrack(id: String) async throws -> Track? {
        let token = SessionStore.shared.session?.accessToken
        let query: [String: String] = [
            "select": "*,artists(artist_name)",
            "id": "eq.\(id)",
            "limit": "1"
        ]
        let rows = try await sb.select(Track.self, from: "tracks", query: query, accessToken: token)
        return rows.first
    }

    /// Top trending track over alle genres (voor featured banner).
    func fetchFeatured() async throws -> Track? {
        let token = SessionStore.shared.session?.accessToken
        let query: [String: String] = [
            "select": "*,artists(artist_name)",
            "status": "eq.live",
            "order": "weighted_minutes_total.desc.nullslast,stream_count.desc",
            "limit": "1"
        ]
        let rows = try await sb.select(Track.self, from: "tracks", query: query, accessToken: token)
        return rows.first
    }
}
