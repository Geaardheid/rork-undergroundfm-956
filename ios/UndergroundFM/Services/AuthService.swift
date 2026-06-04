//
//  AuthService.swift
//  UndergroundFM
//
//  High-level auth flows: sign up + create profile + invite code claim.
//

import Foundation

/// Resultaat van een registratiepoging. Bij e-mailbevestiging kan er nog geen
/// sessie zijn — dan moeten we naar het verify-scherm i.p.v. een fout te tonen.
nonisolated enum SignUpOutcome {
    case completed(AppUser)
    case needsConfirmation
}

@MainActor
final class AuthService {
    static let shared = AuthService()
    private let sb = SupabaseService.shared

    private init() {}

    // MARK: - Sign up flow

    /// Registreer fan: maakt auth user aan. Als er direct een sessie is
    /// (e-mailbevestiging uit), wordt de users-row meteen aangemaakt en
    /// `.completed` teruggegeven. Anders `.needsConfirmation` — de users-row
    /// volgt na e-mailbevestiging via `completeFan`.
    //
    // NB: Stel de redirect URL in Supabase Dashboard → Authentication → URL
    // Configuration in op: undergroundfm://auth/callback
    func signUpFan(email: String, password: String, displayName: String, language: AppLanguage) async throws -> SignUpOutcome {
        let result = try await sb.signUp(email: email, password: password)

        guard let session = await sessionAfterSignUp(email: email, password: password, result: result) else {
            return .needsConfirmation
        }

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
        return .completed(userRow)
    }

    /// Rond een fan-registratie af na e-mailbevestiging.
    func completeFan(email: String, password: String, displayName: String, language: AppLanguage) async throws -> AppUser {
        let session = try await sb.signIn(email: email, password: password)
        let user = try await fetchOrCreateUserRow(
            session: session,
            displayName: displayName,
            role: .consumer,
            isFoundingArtist: false,
            language: language
        )
        SessionStore.shared.save(session)
        return user
    }

    /// Registreer artist: maakt auth user, users row (role=artist), claimt invite code, maakt artists row.
    func signUpArtist(email: String, password: String, displayName: String, inviteCode: String, language: AppLanguage) async throws -> SignUpOutcome {
        // Stap 1: valideer code (zonder sessie — invite_codes_verify policy laat anon select toe)
        let code = inviteCode.uppercased().trimmingCharacters(in: .whitespaces)
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
        guard let session = await sessionAfterSignUp(email: email, password: password, result: result) else {
            // E-mailbevestiging vereist — provisioning gebeurt na bevestiging.
            return .needsConfirmation
        }

        // Stap 3-5: users row, artists row, claim invite code.
        let user = try await provisionArtist(
            session: session,
            email: email,
            displayName: displayName,
            code: code,
            language: language
        )
        SessionStore.shared.save(session)
        return .completed(user)
    }

    /// Rond een artiest-registratie af na e-mailbevestiging.
    func completeArtist(email: String, password: String, displayName: String, inviteCode: String, language: AppLanguage) async throws -> AppUser {
        let session = try await sb.signIn(email: email, password: password)
        let code = inviteCode.uppercased().trimmingCharacters(in: .whitespaces)
        let user = try await provisionArtist(
            session: session,
            email: email,
            displayName: displayName,
            code: code,
            language: language
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

    /// Probeer een sessie te bemachtigen direct na signup. Geeft `nil` terug als
    /// e-mailbevestiging vereist is (geen token + sign-in faalt nog).
    private func sessionAfterSignUp(
        email: String,
        password: String,
        result: (userId: String, accessToken: String?, refreshToken: String?)
    ) async -> AuthSession? {
        if let token = result.accessToken, let refresh = result.refreshToken {
            return AuthSession(accessToken: token, refreshToken: refresh, userId: result.userId, email: email)
        }
        return try? await sb.signIn(email: email, password: password)
    }

    /// Haal de bestaande users-row op of maak hem aan (idempotent).
    private func fetchOrCreateUserRow(
        session: AuthSession,
        displayName: String?,
        role: UserRole,
        isFoundingArtist: Bool,
        language: AppLanguage
    ) async throws -> AppUser {
        let existing: [AppUser] = try await sb.select(
            AppUser.self,
            from: "users",
            query: ["id": "eq.\(session.userId)", "select": "*", "limit": "1"],
            accessToken: session.accessToken
        )
        if let row = existing.first { return row }
        return try await createOrUpdateUserRow(
            userId: session.userId,
            email: session.email,
            displayName: displayName,
            role: role,
            isFoundingArtist: isFoundingArtist,
            language: language,
            accessToken: session.accessToken
        )
    }

    /// Maakt users-row + artists-row aan en claimt de invite code. Idempotent:
    /// als de users-row al bestaat, wordt die teruggegeven zonder dubbel werk.
    private func provisionArtist(
        session: AuthSession,
        email: String,
        displayName: String,
        code: String,
        language: AppLanguage
    ) async throws -> AppUser {
        let existing: [AppUser] = try await sb.select(
            AppUser.self,
            from: "users",
            query: ["id": "eq.\(session.userId)", "select": "*", "limit": "1"],
            accessToken: session.accessToken
        )
        if let row = existing.first { return row }

        let isFounding = code.hasPrefix("FOUNDING") || code.hasPrefix("FA")
        let user = try await createOrUpdateUserRow(
            userId: session.userId,
            email: email,
            displayName: displayName,
            role: .artist,
            isFoundingArtist: isFounding,
            language: language,
            accessToken: session.accessToken
        )

        let sharePct = isFounding ? 0.60 : 0.50
        _ = try await sb.insert(
            InsertResult.self,
            into: "artists",
            values: [
                "user_id": session.userId,
                "artist_name": displayName,
                "invite_code_used": code,
                "revenue_share_pct": sharePct,
                "verified": false
            ],
            accessToken: session.accessToken
        )

        let codes: [InviteCodeRow] = try await sb.select(
            InviteCodeRow.self,
            from: "invite_codes",
            query: ["code": "eq.\(code)", "select": "*", "limit": "1"],
            accessToken: session.accessToken
        )
        if let inviteRow = codes.first {
            let newCount = (inviteRow.useCount ?? 0) + 1
            try await sb.update(
                table: "invite_codes",
                query: ["code": "eq.\(code)"],
                values: [
                    "used_by": session.userId,
                    "used_at": ISO8601DateFormatter().string(from: Date()),
                    "use_count": newCount
                ],
                accessToken: session.accessToken
            )
        }
        return user
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
