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
    @State private var splashLogoIn: Bool = false

    var body: some View {
        Group {
            if auth.isBooting {
                ZStack {
                    CinematicBackground()
                        .ignoresSafeArea()
                        .allowsHitTesting(false)

                    LogoView()
                        .opacity(splashLogoIn ? 1 : 0)
                        .scaleEffect(splashLogoIn ? 1 : 0.88)
                        .animation(.easeOut(duration: 0.9), value: splashLogoIn)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear { splashLogoIn = true }
                .onDisappear { splashLogoIn = false }
                .transition(.opacity)
            } else if auth.isAuthenticated {
                MainTabView(l10n: l10n)
                    .transition(.opacity)
            } else if auth.awaitingConfirmation {
                VerifyEmailView(l10n: l10n)
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
        .onChange(of: auth.awaitingConfirmation) { _, newValue in
            if newValue { showRegister = false }
        }
        .onChange(of: auth.isAuthenticated) { _, newValue in
            if newValue { showRegister = false }
        }
        .animation(.easeInOut(duration: 0.25), value: auth.isAuthenticated)
        .animation(.easeInOut(duration: 0.25), value: auth.isBooting)
        .animation(.easeInOut(duration: 0.25), value: auth.awaitingConfirmation)
        .animation(.easeInOut(duration: 0.25), value: onboardingCompleted)
    }
}

// Legacy entry — UndergroundFMApp now uses RootView directly.
struct ContentView: View {
    var body: some View {
        RootView(l10n: L10n.shared)
    }
}
