//
//  OrientationManager.swift
//  UndergroundFM
//
//  Centraal beheer van toegestane scherm-oriëntaties. De app is portrait-only,
//  behalve wanneer de videoclip-speler zichtbaar is — dan is landscape toegestaan.
//

import UIKit

@MainActor
final class OrientationManager {
    static let shared = OrientationManager()
    private init() {}

    /// De huidige toegestane oriëntaties, gelezen door de AppDelegate.
    private(set) var mask: UIInterfaceOrientationMask = .portrait

    /// Sta landscape toe (gebruikt door de clip-speler).
    func allowLandscape() {
        mask = [.portrait, .landscapeLeft, .landscapeRight]
        applyGeometry()
    }

    /// Forceer terug naar portrait (rest van de app).
    func lockPortrait() {
        mask = .portrait
        applyGeometry()
    }

    private func applyGeometry() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0 is UIWindowScene }) as? UIWindowScene else { return }
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
        scene.windows.forEach { $0.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations() }
    }
}
