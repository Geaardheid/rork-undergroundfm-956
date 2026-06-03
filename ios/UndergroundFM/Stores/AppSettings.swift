//
//  AppSettings.swift
//  UndergroundFM
//
//  Lichte, persistente app-instellingen (UserDefaults).
//

import Foundation
import Observation

@Observable
final class AppSettings {
    static let shared = AppSettings()

    private let notificationsKey = "settings.notifications_enabled"

    var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: notificationsKey)
        }
    }

    private init() {
        if UserDefaults.standard.object(forKey: notificationsKey) == nil {
            self.notificationsEnabled = true
        } else {
            self.notificationsEnabled = UserDefaults.standard.bool(forKey: notificationsKey)
        }
    }
}
