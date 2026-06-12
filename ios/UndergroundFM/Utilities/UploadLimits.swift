//
//  UploadLimits.swift
//  UndergroundFM
//
//  Centrale bestandsgrootte-limieten voor de track-upload flow.
//  Pas deze constanten aan om de limieten te wijzigen.
//

import Foundation

enum UploadLimits {
    /// Maximale grootte van het audiobestand (50 MB).
    static let maxAudioBytes: Int = 50 * 1024 * 1024
    /// Maximale grootte van de videoclip (500 MB).
    static let maxVideoBytes: Int = 500 * 1024 * 1024
    /// Maximale grootte van de cover-afbeelding (10 MB).
    static let maxCoverBytes: Int = 10 * 1024 * 1024
}
