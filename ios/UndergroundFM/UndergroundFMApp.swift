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
        }
    }
}
