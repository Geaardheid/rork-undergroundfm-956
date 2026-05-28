//
//  AuthService.swift
//  UndergroundFM
//
//  High-level auth flows: sign up + create profile + invite code claim.
//

import Foundation

@MainActor
final class AuthService {
    static let shared = AuthService()
    private let sb = SupabaseService.shared

    private init() {}

    // MARK: - Sign up flow

    /// Registreer fan: maakt auth user + users row aan.
    func signUpFan(email: String, password: String, displayName: String, language: AppLanguage) async throws -> AppUser {
        let result = try await sb.signUp(email: email, password: password)

        // Probeer in te loggen om sessie te krijgen (signup geeft niet altijd token mee bij email confirmation off/on)
        let session = try await ensureSession(email: email, password: password, fallbackToken: result.accessToken, fallbackRefresh: result.refreshToken, userId: result.userId)

        let userRow = try await createOrUpdateUserRow(
            userId: result.userId,
            email: email,
            displayName: displayName,
            role: .consumer,
            isFoundingArtist: false,
            language: language,
            accessToken: session.accessToken
        )
        SessionStore.shared.save(session)
        return userRow
    }

    /// Registreer artist: maakt auth user, users row (role=artist), claimt invite code, maakt artists row.
    func signUpArtist(email: String, password: String, displayName: String, inviteCode: String, language: AppLanguage) async throws -> AppUser {
        // Stap 1: valideer code (zonder sessie — invite_codes_verify policy laat anon select toe)
        let code = inviteCode.uppercased().trimmingCharacters(in: .whitespaces)
        let isFounding = code.uppercased().hasPrefix("FOUND")
        let codes: [InviteCodeRow] = try await sb.select(
            InviteCodeRow.self,
            from: "invite_codes",
            query: [
                "code": "eq.\(code)",
                "is_active": "eq.true",
                "select": "*",
                "limit": "1"
            ]
        )
        guard let inviteRow = codes.first else {
            throw SupabaseError.message(L10n.shared.t("invite.invalid"))
        }
        if let max = inviteRow.maxUses, let used = inviteRow.useCount, used >= max {
            throw SupabaseError.message(L10n.shared.t("invite.invalid"))
        }

        // Stap 2: sign up
        let result = try await sb.signUp(email: email, password: password)
        let session = try await ensureSession(email: email, password: password, fallbackToken: result.accessToken, fallbackRefresh: result.refreshToken, userId: result.userId)

        // Stap 3: users row
        let user = try await createOrUpdateUserRow(
            userId: result.userId,
            email: email,
            displayName: displayName,
            role: .artist,
            isFoundingArtist: isFounding,
            language: language,
            accessToken: session.accessToken
        )

        // Stap 4: artists row
        let sharePct = isFounding ? 0.60 : 0.50
        _ = try await sb.insert(
            InsertResult.self,
            into: "artists",
            values: [
                "user_id": result.userId,
                "artist_name": displayName,
                "invite_code_used": code,
                "revenue_share_pct": sharePct,
                "verified": false
            ],
            accessToken: session.accessToken
        )

        // Stap 5: claim invite code (use_count + 1, used_by, used_at)
        let newCount = (inviteRow.useCount ?? 0) + 1
        try await sb.update(
            table: "invite_codes",
            query: ["code": "eq.\(code)"],
            values: [
                "used_by": result.userId,
                "used_at": ISO8601DateFormatter().string(from: Date()),
                "use_count": newCount
            ],
            accessToken: session.accessToken
        )

        SessionStore.shared.save(session)
        return user
    }

    // MARK: - Sign in

    func signIn(email: String, password: String) async throws -> AppUser {
        let session = try await sb.signIn(email: email, password: password)
        SessionStore.shared.save(session)
        // Haal users row
        let users: [AppUser] = try await sb.select(
            AppUser.self,
            from: "users",
            query: ["id": "eq.\(session.userId)", "select": "*", "limit": "1"],
            accessToken: session.accessToken
        )
        if let user = users.first {
            return user
        }
        // Geen row (oude account) — maak default consumer row aan
        return try await createOrUpdateUserRow(
            userId: session.userId,
            email: email,
            displayName: nil,
            role: .consumer,
            isFoundingArtist: false,
            language: L10n.shared.language,
            accessToken: session.accessToken
        )
    }

    func signOut() async {
        if let token = SessionStore.shared.session?.accessToken {
            try? await sb.signOut(accessToken: token)
        }
        SessionStore.shared.clear()
    }

    // MARK: - Helpers

    private struct InsertResult: Decodable { let id: String? }

    private func ensureSession(email: String, password: String, fallbackToken: String?, fallbackRefresh: String?, userId: String) async throws -> AuthSession {
        if let token = fallbackToken, let refresh = fallbackRefresh {
            return AuthSession(accessToken: token, refreshToken: refresh, userId: userId, email: email)
        }
        // Email confirmation aan? Probeer signIn — kan falen, dan tonen we duidelijke fout.
        return try await sb.signIn(email: email, password: password)
    }

    private func createOrUpdateUserRow(
        userId: String,
        email: String,
        displayName: String?,
        role: UserRole,
        isFoundingArtist: Bool,
        language: AppLanguage,
        accessToken: String
    ) async throws -> AppUser {
        var values: [String: Any] = [
            "id": userId,
            "email": email,
            "role": role.rawValue,
            "is_founding_artist": isFoundingArtist,
            "preferred_language": language.rawValue
        ]
        if let displayName = displayName {
            values["display_name"] = displayName
        }
        let inserted: [AppUser] = try await sb.insert(
            AppUser.self,
            into: "users",
            values: values,
            accessToken: accessToken
        )
        if let row = inserted.first {
            return row
        }
        throw SupabaseError.invalidResponse
    }
}

// MARK: - SessionStore (token persistence)

@MainActor
final class SessionStore {
    static let shared = SessionStore()
    private let key = "auth_session_v1"

    private(set) var session: AuthSession?

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let s = try? JSONDecoder().decode(AuthSession.self, from: data) {
            self.session = s
        }
    }

    func save(_ s: AuthSession) {
        self.session = s
        if let data = try? JSONEncoder().encode(s) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func clear() {
        self.session = nil
        UserDefaults.standard.removeObject(forKey: key)
    }
}
