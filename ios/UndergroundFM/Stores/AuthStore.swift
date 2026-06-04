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

    /// Restore a persisted session on app launch so the user stays logged in.
    func restoreSession() async {
        defer { isBooting = false }
        guard let stored = SessionStore.shared.session else { return }

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

    func signUpFan(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let user = try await AuthService.shared.signUpFan(
                email: email,
                password: password,
                displayName: displayName,
                language: L10n.shared.language
            )
            self.currentUser = user
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signUpArtist(email: String, password: String, displayName: String, inviteCode: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let user = try await AuthService.shared.signUpArtist(
                email: email,
                password: password,
                displayName: displayName,
                inviteCode: inviteCode,
                language: L10n.shared.language
            )
            self.currentUser = user
            await self.loadArtistId()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() async {
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
    func becomeArtist(name: String, bio: String, genreTags: [String], instagramUrl: String) async -> Bool {
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
                instagramUrl: instagramUrl
            )
            var updated = user
            updated.role = .artist
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
}
