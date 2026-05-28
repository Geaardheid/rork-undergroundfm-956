//
//  Theme.swift
//  UndergroundFM
//
//  Design tokens — exacte spec uit master context.
//

import SwiftUI

enum AppColors {
    // Achtergronden
    static let bg = Color(hex: 0x0A0A0A)
    static let card = Color(hex: 0x181818)
    static let cardHover = Color(hex: 0x222222)
    static let border = Color(hex: 0x2A2A2A)
    static let borderLight = Color(hex: 0x333333)

    // Accent
    static let yellow = Color(hex: 0xFFE000)
    static let yellowDark = Color(hex: 0xCCB400)
    static let yellowText = Color(hex: 0x0A0A0A)

    // Tekst
    static let textPrimary = Color.white
    static let textSecond = Color(hex: 0xAAAAAA)
    static let textMuted = Color(hex: 0x666666)

    // Status
    static let success = Color(hex: 0x34C759)
    static let warning = Color(hex: 0xFF9500)
    static let error = Color(hex: 0xFF3B30)
    static let info = Color(hex: 0x0A84FF)
}

enum AppFontSize {
    static let xs: CGFloat = 11
    static let sm: CGFloat = 13
    static let base: CGFloat = 15
    static let md: CGFloat = 17
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 30
    static let hero: CGFloat = 40
}

enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

enum AppRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 10
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
