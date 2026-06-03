//
//  ContentView.swift
//  UndergroundFM
//

import SwiftUI

struct RootView: View {
    @Environment(AuthStore.self) private var auth
    @Bindable var l10n: L10n

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
            } else {
                LoginView(l10n: l10n)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: auth.isAuthenticated)
        .animation(.easeInOut(duration: 0.25), value: auth.isBooting)
    }
}

// Legacy entry — UndergroundFMApp now uses RootView directly.
struct ContentView: View {
    var body: some View {
        RootView(l10n: L10n.shared)
    }
}
