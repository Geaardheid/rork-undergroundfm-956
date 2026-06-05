//
//  UndergroundFMApp.swift
//  UndergroundFM
//

import SwiftUI

@main
struct UndergroundFMApp: App {
    @State private var auth = AuthStore()
    @State private var l10n = L10n.shared
    @State private var subscription = SubscriptionService.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView(l10n: l10n)
                .environment(auth)
                .environment(subscription)
                .preferredColorScheme(.dark)
                .task {
                    subscription.configure(auth: auth)
                    await auth.restoreSession()
                }
                .onOpenURL { url in
                    // Deep links: undergroundfm://payment-success of auth/callback
                    guard url.scheme?.lowercased() == "undergroundfm" else { return }
                    switch url.host {
                    case "payment-success":
                        Task { await subscription.refresh() }
                    default:
                        Task { await auth.restoreSession() }
                    }
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Re-check de abonnementsstatus bij terugkeer naar de app (bv. na
            // betalen op het web) zodat content ontgrendelt zonder re-login.
            if newPhase == .active {
                Task { await subscription.refresh() }
            }
        }
    }
}
