//
//  Track.swift
//  UndergroundFM
//

import Foundation

nonisolated struct Track: Codable, Identifiable, Hashable {
    let id: String
    let artistId: String
    let title: String
    let description: String?
    let audioUrl: String?
    let videoUrl: String?
    let thumbnailUrl: String?
    let duration: Int?
    let streamCount: Int64
    let likeCount: Int64
    let genreTags: [String]
    let explicit: Bool
    let status: String
    let weightedMinutesTotal: Double?
    let createdAt: String?

    /// Embedded artist via PostgREST join: tracks?select=*,artists(artist_name)
    let artists: EmbeddedArtist?

    var artistName: String { artists?.artistName ?? "Unknown" }

    enum CodingKeys: String, CodingKey {
        case id
        case artistId = "artist_id"
        case title, description
        case audioUrl = "audio_url"
        case videoUrl = "video_url"
        case thumbnailUrl = "thumbnail_url"
        case duration
        case streamCount = "stream_count"
        case likeCount = "like_count"
        case genreTags = "genre_tags"
        case explicit, status
        case weightedMinutesTotal = "weighted_minutes_total"
        case createdAt = "created_at"
        case artists
    }
}

nonisolated struct EmbeddedArtist: Codable, Hashable {
    let artistName: String
    enum CodingKeys: String, CodingKey {
        case artistName = "artist_name"
    }
}

/// Genre sectie definitie voor de home feed.
nonisolated struct GenreSection: Identifiable, Hashable {
    let id: String
    let titleKey: String
    let emoji: String
    let genre: String
    let orderBy: OrderBy

    enum OrderBy: String {
        case trending = "weighted_minutes_total.desc.nullslast"
        case newest = "created_at.desc"
    }

    static let all: [GenreSection] = [
        GenreSection(id: "trending_rap",   titleKey: "feed.trending_rap",   emoji: "🔥", genre: "rap",       orderBy: .trending),
        GenreSection(id: "new_drill",      titleKey: "feed.new_drill",      emoji: "⚡", genre: "drill",     orderBy: .newest),
        GenreSection(id: "new_afro",       titleKey: "feed.new_afro",       emoji: "🌍", genre: "afro",      orderBy: .newest),
        GenreSection(id: "trending_trap",  titleKey: "feed.trending_trap",  emoji: "💎", genre: "trap",      orderBy: .trending),
        GenreSection(id: "new_rb",         titleKey: "feed.new_rb",         emoji: "🎵", genre: "rb",        orderBy: .newest),
        GenreSection(id: "new_house",      titleKey: "feed.new_house",      emoji: "🏠", genre: "house",     orderBy: .newest),
    ]
}
