//
//  AuthStore.swift
//  UndergroundFM
//

import Foundation

@Observable
final class AuthStore {
    var currentUser: AppUser?
    var artistName: String?
    var isLoading: Bool = false
    var errorMessage: String?

    var isAuthenticated: Bool { currentUser != nil }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let user = try await AuthService.shared.signIn(email: email, password: password)
            self.currentUser = user
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
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() async {
        await AuthService.shared.signOut()
        self.currentUser = nil
        self.artistName = nil
        self.errorMessage = nil
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
