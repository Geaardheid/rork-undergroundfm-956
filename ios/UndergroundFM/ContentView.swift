//
//  ContentView.swift
//  UndergroundFM
//

import SwiftUI

struct RootView: View {
    @Environment(AuthStore.self) private var auth
    @Bindable var l10n: L10n

    @AppStorage("onboarding_completed") private var onboardingCompleted: Bool = false
    @State private var showRegister: Bool = false
    @State private var registerAsArtist: Bool = false

    var body: some View {
        Group {
            if auth.isBooting {
                LogoView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.bg.ignoresSafeArea())
                    .transition(.opacity)
            } else if auth.isAuthenticated {
                MainTabView(l10n: l10n)
                    .transition(.opacity)
            } else if !onboardingCompleted {
                OnboardingView(
                    l10n: l10n,
                    onLogin: { onboardingCompleted = true },
                    onRegister: { isArtist in
                        registerAsArtist = isArtist
                        onboardingCompleted = true
                        showRegister = true
                    }
                )
                .transition(.opacity)
            } else {
                LoginView(l10n: l10n)
                    .transition(.opacity)
            }
        }
        .sheet(isPresented: $showRegister) {
            RegisterView(l10n: l10n, initialIsArtist: registerAsArtist)
                .presentationBackground(AppColors.bg)
        }
        .animation(.easeInOut(duration: 0.25), value: auth.isAuthenticated)
        .animation(.easeInOut(duration: 0.25), value: auth.isBooting)
        .animation(.easeInOut(duration: 0.25), value: onboardingCompleted)
    }
}

// Legacy entry — UndergroundFMApp now uses RootView directly.
struct ContentView: View {
    var body: some View {
        RootView(l10n: L10n.shared)
    }
}
