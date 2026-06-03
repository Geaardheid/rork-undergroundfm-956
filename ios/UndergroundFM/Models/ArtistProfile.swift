//
//  ArtistProfile.swift
//  UndergroundFM
//
//  Publiek artiestenprofiel + navigatie-route + maand-statistieken.
//

import Foundation

/// Volledig artiestenprofiel zoals getoond op de (publieke) artiestenpagina.
nonisolated struct ArtistProfile: Codable, Identifiable, Hashable {
    let id: String
    let userId: String?
    let artistName: String
    let bio: String?
    let genreTags: [String]
    let instagramUrl: String?
    let verified: Bool
    let users: EmbeddedArtistUser?

    var isFoundingArtist: Bool { users?.isFoundingArtist ?? false }
    var avatarUrl: String? { users?.avatarUrl }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case artistName = "artist_name"
        case bio
        case genreTags = "genre_tags"
        case instagramUrl = "instagram_url"
        case verified
        case users
    }
}

nonisolated struct EmbeddedArtistUser: Codable, Hashable {
    let isFoundingArtist: Bool?
    let displayName: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case isFoundingArtist = "is_founding_artist"
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}

/// Maand-statistieken voor een artiest, berekend uit view_events.
nonisolated struct ArtistMonthStats: Equatable {
    let supporters: Int
    let scenePoints: Double
    let ranking: Int
    let totalArtists: Int

    static let empty = ArtistMonthStats(supporters: 0, scenePoints: 0, ranking: 0, totalArtists: 0)
}

/// Type-veilige navigatie-route naar een publiek artiestenprofiel.
nonisolated struct ArtistRoute: Hashable, Identifiable {
    let artistId: String
    let artistName: String
    var id: String { artistId }
}
