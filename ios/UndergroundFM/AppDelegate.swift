//
//  AppDelegate.swift
//  UndergroundFM
//
//  Levert de dynamische oriëntatie-mask aan UIKit. De waarde wordt centraal
//  beheerd door OrientationManager — portrait-only, met landscape-uitzondering
//  voor de videoclip-speler.
//

import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        OrientationManager.shared.mask
    }
}
