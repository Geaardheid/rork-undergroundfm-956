//
//  SceneStatsService.swift
//  UndergroundFM
//
//  Berekent maand-statistieken (supporters, scene punten, underground ranking)
//  uit de view_events tabel. Ranking wordt client-side berekend over alle artiesten.
//

import Foundation

@MainActor
final class SceneStatsService {
    static let shared = SceneStatsService()
    private let sb = SupabaseService.shared

    private init() {}

    /// Eén view_events rij met de bijbehorende artist_id via embedded join op tracks.
    private nonisolated struct EventRow: Decodable {
        let userId: String?
        let weightedScore: Double?
        let tracks: TrackRef?

        struct TrackRef: Decodable {
            let artistId: String?
            enum CodingKeys: String, CodingKey { case artistId = "artist_id" }
        }

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case weightedScore = "weighted_score"
            case tracks
        }
    }

    /// Haalt alle events van deze maand op en berekent de stats voor één artiest,
    /// inclusief de ranking ten opzichte van alle andere artiesten.
    func fetchStats(for artistId: String) async throws -> ArtistMonthStats {
        let token = SessionStore.shared.session?.accessToken
        let monthStart = Self.startOfMonthISO()

        let rows: [EventRow] = try await sb.select(
            EventRow.self,
            from: "view_events",
            query: [
                "select": "user_id,weighted_score,tracks(artist_id)",
                "created_at": "gte.\(monthStart)",
                "limit": "20000"
            ],
            accessToken: token
        )

        // Aggregeer per artiest: unieke supporters + som van weighted_score.
        var supportersByArtist: [String: Set<String>] = [:]
        var pointsByArtist: [String: Double] = [:]

        for row in rows {
            guard let aId = row.tracks?.artistId else { continue }
            pointsByArtist[aId, default: 0] += row.weightedScore ?? 0
            if let uid = row.userId {
                supportersByArtist[aId, default: []].insert(uid)
            }
        }

        let supporters = supportersByArtist[artistId]?.count ?? 0
        let points = pointsByArtist[artistId] ?? 0

        // Ranking: sorteer alle artiesten op punten (aflopend).
        let ranked = pointsByArtist
            .sorted { $0.value > $1.value }
            .map { $0.key }
        let totalArtists = ranked.count
        let ranking: Int
        if let idx = ranked.firstIndex(of: artistId) {
            ranking = idx + 1
        } else {
            ranking = totalArtists + 1
        }

        return ArtistMonthStats(
            supporters: supporters,
            scenePoints: points,
            ranking: ranking,
            totalArtists: max(totalArtists, ranking)
        )
    }

    /// ISO-8601 string van de eerste dag van de huidige maand (UTC).
    private nonisolated static func startOfMonthISO() -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .current
        let comps = cal.dateComponents([.year, .month], from: Date())
        let start = cal.date(from: comps) ?? Date()
        let fmt = ISO8601DateFormatter()
        fmt.timeZone = TimeZone(identifier: "UTC")
        return fmt.string(from: start)
    }
}
