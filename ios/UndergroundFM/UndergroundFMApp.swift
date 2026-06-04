//
//  UndergroundFMApp.swift
//  UndergroundFM
//

import SwiftUI

@main
struct UndergroundFMApp: App {
    @State private var auth = AuthStore()
    @State private var l10n = L10n.shared

    var body: some Scene {
        WindowGroup {
            RootView(l10n: l10n)
                .environment(auth)
                .preferredColorScheme(.dark)
                .task {
                    await auth.restoreSession()
                }
                .onOpenURL { url in
                    // Deep link na e-mailbevestiging: undergroundfm://auth/callback
                    guard url.scheme?.lowercased() == "undergroundfm" else { return }
                    Task { await auth.restoreSession() }
                }
        }
    }
}
