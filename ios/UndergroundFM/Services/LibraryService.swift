//
//  LibraryService.swift
//  UndergroundFM
//
//  Hulpqueries voor de Bibliotheek-tab (afspeelgeschiedenis-volgorde).
//

import Foundation

@MainActor
final class LibraryService {
    static let shared = LibraryService()
    private let sb = SupabaseService.shared

    private init() {}

    private nonisolated struct PlayEventRow: Decodable {
        let trackId: String
        enum CodingKeys: String, CodingKey { case trackId = "track_id" }
    }

    /// Track-ID's in volgorde van laatst afgespeeld (meest recent eerst, uniek).
    func fetchRecentlyPlayedTrackIds(userId: String) async throws -> [String] {
        let token = SessionStore.shared.session?.accessToken
        let rows: [PlayEventRow] = try await sb.select(
            PlayEventRow.self,
            from: "view_events",
            query: [
                "user_id": "eq.\(userId)",
                "select": "track_id",
                "order": "created_at.desc",
                "limit": "300"
            ],
            accessToken: token
        )
        var seen = Set<String>()
        var ordered: [String] = []
        for row in rows where !seen.contains(row.trackId) {
            seen.insert(row.trackId)
            ordered.append(row.trackId)
        }
        return ordered
    }
}
