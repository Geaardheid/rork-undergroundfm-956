//
//  AppUser.swift
//  UndergroundFM
//

import Foundation

nonisolated enum UserRole: String, Codable {
    case consumer
    case artist
    case admin
}

nonisolated struct AppUser: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    var displayName: String?
    var role: UserRole
    var isFoundingArtist: Bool
    var preferredLanguage: String
    var subscriptionStatus: String?
    var avatarUrl: String?

    var hasActiveSubscription: Bool {
        subscriptionStatus == "active" || subscriptionStatus == "trial"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case role
        case isFoundingArtist = "is_founding_artist"
        case preferredLanguage = "preferred_language"
        case subscriptionStatus = "subscription_status"
        case avatarUrl = "avatar_url"
    }
}

nonisolated struct InviteCodeRow: Codable {
    let id: String
    let code: String
    let isActive: Bool
    let maxUses: Int?
    let useCount: Int?
    let expiresAt: String?

    enum CodingKeys: String, CodingKey {
        case id, code
        case isActive = "is_active"
        case maxUses = "max_uses"
        case useCount = "use_count"
        case expiresAt = "expires_at"
    }
}

nonisolated struct AuthSession: Codable {
    let accessToken: String
    let refreshToken: String
    let userId: String
    let email: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case userId
        case email
    }
}
