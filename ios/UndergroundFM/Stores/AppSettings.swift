//
//  AppSettings.swift
//  UndergroundFM
//
//  Lichte, persistente app-instellingen (UserDefaults).
//

import Foundation
import Observation

nonisolated enum AudioQuality: String, CaseIterable, Identifiable {
    case high, normal, low
    var id: String { rawValue }
}

@Observable
final class AppSettings {
    static let shared = AppSettings()

    private let notificationsKey = "settings.notifications_enabled"
    private let audioQualityKey = "settings.audio_quality"
    private let artistNotifyPrefix = "settings.notify_artist."

    var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: notificationsKey)
        }
    }

    var audioQuality: AudioQuality {
        didSet {
            UserDefaults.standard.set(audioQuality.rawValue, forKey: audioQualityKey)
        }
    }

    /// Per-artiest notificatievoorkeur (alleen UI — opgeslagen in UserDefaults).
    var artistNotifications: [String: Bool] = [:]

    private init() {
        if UserDefaults.standard.object(forKey: notificationsKey) == nil {
            self.notificationsEnabled = true
        } else {
            self.notificationsEnabled = UserDefaults.standard.bool(forKey: notificationsKey)
        }

        if let raw = UserDefaults.standard.string(forKey: audioQualityKey),
           let q = AudioQuality(rawValue: raw) {
            self.audioQuality = q
        } else {
            self.audioQuality = .normal
        }
    }

    /// Of nieuwe-upload notificaties aanstaan voor een artiest (default: aan).
    func isArtistNotificationOn(_ artistId: String) -> Bool {
        if let cached = artistNotifications[artistId] { return cached }
        let key = artistNotifyPrefix + artistId
        if UserDefaults.standard.object(forKey: key) == nil { return true }
        return UserDefaults.standard.bool(forKey: key)
    }

    func setArtistNotification(_ artistId: String, _ isOn: Bool) {
        artistNotifications[artistId] = isOn
        UserDefaults.standard.set(isOn, forKey: artistNotifyPrefix + artistId)
    }
}
