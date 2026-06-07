//
//  AuthStore.swift
//  UndergroundFM
//

import Foundation

@Observable
final class AuthStore {
    var currentUser: AppUser?
    var artistName: String?
    var artistId: String?
    var isLoading: Bool = false
    var errorMessage: String?

    var isAuthenticated: Bool { currentUser != nil }
    var isBooting: Bool = true

    /// True wanneer een registratie wacht op e-mailbevestiging.
    var awaitingConfirmation: Bool = false
    /// E-mailadres dat op bevestiging wacht (voor de verify-schermtekst).
    var pendingEmail: String?

    private let pendingKey = "pending_signup_v1"

    /// Restore a persisted session on app launch (or after returning from email
    /// confirmation) so the user stays logged in.
    func restoreSession() async {
        defer { isBooting = false }

        // 1) Hervat een normale opgeslagen sessie.
        if let stored = SessionStore.shared.session {
            await restoreStoredSession(stored)
            return
        }

        // 2) Wacht een registratie op e-mailbevestiging? Probeer af te ronden.
        if let pending = loadPending() {
            awaitingConfirmation = true
            pendingEmail = pending.email
            await tryCompletePendingSignUp(pending)
        }
    }

    private func restoreStoredSession(_ stored: AuthSession) async {
        // Refresh the access token (they expire ~1h); fall back to the stored token.
        var token = stored.accessToken
        if let refreshed = try? await SupabaseService.shared.refreshSession(refreshToken: stored.refreshToken) {
            SessionStore.shared.save(refreshed)
            token = refreshed.accessToken
        }

        do {
            let users: [AppUser] = try await SupabaseService.shared.select(
                AppUser.self,
                from: "users",
                query: ["id": "eq.\(stored.userId)", "select": "*", "limit": "1"],
                accessToken: token
            )
            guard let user = users.first else {
                // Token no longer valid / user removed — clear stale session.
                SessionStore.shared.clear()
                return
            }
            self.currentUser = user
            if user.role == .artist {
                await self.loadArtistId()
            }
        } catch {
            // Keep the session; transient network errors shouldn't force a logout.
        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let user = try await AuthService.shared.signIn(email: email, password: password)
            self.currentUser = user
            if user.role == .artist {
                await self.loadArtistId()
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signUpFan(email: String, password: String, displayName: String, genrePreferences: [String] = []) async {
        isLoading = true
        errorMessage = nil
        do {
            let outcome = try await AuthService.shared.signUpFan(
                email: email,
                password: password,
                displayName: displayName,
                language: L10n.shared.language,
                genrePreferences: genrePreferences
            )
            switch outcome {
            case .completed(let user):
                self.currentUser = user
            case .needsConfirmation:
                savePending(PendingSignUp(
                    email: email,
                    password: password,
                    displayName: displayName,
                    isArtist: false,
                    inviteCode: nil,
                    language: L10n.shared.language.rawValue,
                    genrePreferences: genrePreferences
                ))
                self.awaitingConfirmation = true
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Werk de genre-voorkeuren van de huidige fan bij (vanuit Instellingen).
    /// Past de lokale staat direct aan zodat de home-feed meteen meebeweegt.
    func updateGenrePreferences(_ genres: [String]) async -> Bool {
        guard let user = currentUser,
              let token = SessionStore.shared.session?.accessToken else {
            self.errorMessage = L10n.shared.t("errors.unknown")
            return false
        }
        do {
            try await AuthService.shared.updateGenrePreferences(
                userId: user.id,
                genres: genres,
                accessToken: token
            )
            currentUser?.genrePreferences = genres
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }

    func signUpArtist(email: String, password: String, displayName: String, inviteCode: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let outcome = try await AuthService.shared.signUpArtist(
                email: email,
                password: password,
                displayName: displayName,
                inviteCode: inviteCode,
                language: L10n.shared.language
            )
            switch outcome {
            case .completed(let user):
                self.currentUser = user
                await self.loadArtistId()
            case .needsConfirmation:
                savePending(PendingSignUp(
                    email: email,
                    password: password,
                    displayName: displayName,
                    isArtist: true,
                    inviteCode: inviteCode,
                    language: L10n.shared.language.rawValue,
                    genrePreferences: nil
                ))
                self.awaitingConfirmation = true
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() async {
        MusicPlayer.shared.clear()
        await AuthService.shared.signOut()
        self.currentUser = nil
        self.artistName = nil
        self.artistId = nil
        self.errorMessage = nil
    }

    /// Wijzig wachtwoord: verifieer het huidige wachtwoord en zet daarna het nieuwe.
    func changePassword(current: String, new: String) async -> Bool {
        guard let user = currentUser else {
            self.errorMessage = L10n.shared.t("errors.unknown")
            return false
        }
        isLoading = true
        errorMessage = nil
        do {
            // Verifieer het huidige wachtwoord door opnieuw in te loggen.
            let session = try await SupabaseService.shared.signIn(email: user.email, password: current)
            SessionStore.shared.save(session)
            try await SupabaseService.shared.updatePassword(newPassword: new, accessToken: session.accessToken)
            isLoading = false
            return true
        } catch {
            self.errorMessage = L10n.shared.t("settings.passwordWrong")
            isLoading = false
            return false
        }
    }

    /// Verwijder het account: probeer de auth-user via RPC te verwijderen, ruim de
    /// users-row op en log daarna uit.
    func deleteAccount() async -> Bool {
        guard let user = currentUser,
              let token = SessionStore.shared.session?.accessToken else {
            self.errorMessage = L10n.shared.t("errors.unknown")
            return false
        }
        isLoading = true
        errorMessage = nil

        // Best-effort: SECURITY DEFINER RPC verwijdert de auth.users row (zie schema.sql).
        try? await SupabaseService.shared.rpc("delete_current_user", params: [:], accessToken: token)
        // Ruim de users-row op (RPC met cascade kan dit al hebben gedaan).
        try? await SupabaseService.shared.delete(
            table: "users",
            query: ["id": "eq.\(user.id)"],
            accessToken: token
        )

        await signOut()
        isLoading = false
        return true
    }

    /// Look up the artist ID for the current user and cache it.
    private func loadArtistId() async {
        guard let user = currentUser,
              let token = SessionStore.shared.session?.accessToken,
              user.role == .artist else { return }
        self.artistId = try? await ArtistService.shared.fetchArtistId(
            userId: user.id,
            accessToken: token
        )
    }

    /// Promote current user to artist by creating an artists row + updating users.role.
    func becomeArtist(name: String, bio: String, genreTags: [String], instagramUrl: String, inviteCode: String) async -> Bool {
        guard let user = currentUser,
              let token = SessionStore.shared.session?.accessToken else {
            self.errorMessage = L10n.shared.t("errors.unknown")
            return false
        }
        isLoading = true
        errorMessage = nil
        do {
            let savedName = try await ArtistService.shared.becomeArtist(
                userId: user.id,
                accessToken: token,
                artistName: name,
                bio: bio,
                genreTags: genreTags,
                instagramUrl: instagramUrl,
                inviteCode: inviteCode
            )
            let isFounding = inviteCode.uppercased().hasPrefix("FOUNDING") || inviteCode.uppercased().hasPrefix("FA")
            var updated = user
            updated.role = .artist
            updated.isFoundingArtist = isFounding
            self.currentUser = updated
            self.artistName = savedName
            self.artistId = try? await ArtistService.shared.fetchArtistId(
                userId: user.id,
                accessToken: token
            )
            isLoading = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func clearError() {
        errorMessage = nil
    }

    /// Werk de lokale profielfoto-URL bij na een upload (UI ververst direct).
    func updateAvatarUrl(_ url: String) {
        currentUser?.avatarUrl = url
    }

    /// Werk de gecachte artiestennaam bij na een profielbewerking (UI ververst direct).
    func updateArtistName(_ name: String) {
        artistName = name
        currentUser?.displayName = name
    }

    /// Werk de gecachte abonnementsstatus bij (aangeroepen door SubscriptionService
    /// na een refresh) zodat de gate direct ontgrendelt zonder re-login.
    func updateSubscriptionStatus(_ status: String) {
        currentUser?.subscriptionStatus = status
    }

    // MARK: - E-mailbevestiging (pending signup)

    private func savePending(_ p: PendingSignUp) {
        pendingEmail = p.email
        if let data = try? JSONEncoder().encode(p) {
            UserDefaults.standard.set(data, forKey: pendingKey)
        }
    }

    private func loadPending() -> PendingSignUp? {
        guard let data = UserDefaults.standard.data(forKey: pendingKey) else { return nil }
        return try? JSONDecoder().decode(PendingSignUp.self, from: data)
    }

    private func clearPending() {
        UserDefaults.standard.removeObject(forKey: pendingKey)
        pendingEmail = nil
    }

    /// Probeer een wachtende registratie af te ronden zodra de e-mail bevestigd is.
    ///
    /// Supabase heeft de bevestiging soms nét nog niet verwerkt wanneer de app weer
    /// actief wordt, dus we proberen het tot 3 keer met een korte pauze. Tijdens de
    /// pogingen tonen we een laad-staat en GEEN foutmelding; de pending-gegevens
    /// blijven bewaard tot een poging slaagt zodat een volgende trigger opnieuw kan.
    private func tryCompletePendingSignUp(_ pending: PendingSignUp) async {
        let lang = AppLanguage(rawValue: pending.language) ?? .nl
        let maxAttempts = 3

        isLoading = true
        errorMessage = nil
        awaitingConfirmation = true

        for attempt in 1...maxAttempts {
            do {
                let user: AppUser
                if pending.isArtist, let code = pending.inviteCode {
                    user = try await AuthService.shared.completeArtist(
                        email: pending.email,
                        password: pending.password,
                        displayName: pending.displayName,
                        inviteCode: code,
                        language: lang
                    )
                } else {
                    user = try await AuthService.shared.completeFan(
                        email: pending.email,
                        password: pending.password,
                        displayName: pending.displayName,
                        language: lang,
                        genrePreferences: pending.genrePreferences ?? []
                    )
                }
                // Geslaagd: log in en ruim de pending-gegevens op.
                self.currentUser = user
                if user.role == .artist { await self.loadArtistId() }
                self.awaitingConfirmation = false
                clearPending()
                isLoading = false
                return
            } catch {
                // Nog niet bevestigd (sign-in faalt). Wacht en probeer opnieuw,
                // zonder de pending-gegevens te wissen of een fout te tonen.
                if attempt < maxAttempts {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                }
            }
        }

        // Pas na alle mislukte pogingen: toon de bestaande "nog niet bevestigd"-staat.
        // pending blijft bewaard zodat een volgende scenePhase-active of
        // "Ik heb bevestigd"-tik opnieuw kan proberen.
        isLoading = false
    }

    /// Annuleer de wachtende bevestiging en ga terug naar het inlogscherm.
    func cancelPendingConfirmation() {
        awaitingConfirmation = false
        clearPending()
        SessionStore.shared.clear()
    }
}

nonisolated struct PendingSignUp: Codable {
    let email: String
    let password: String
    let displayName: String
    let isArtist: Bool
    let inviteCode: String?
    let language: String
    /// Optioneel zodat oudere opgeslagen pending-signups blijven decoderen.
    let genrePreferences: [String]?
}
