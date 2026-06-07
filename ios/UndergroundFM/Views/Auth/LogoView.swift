//
//  LogoView.swift
//  UndergroundFM
//

import SwiftUI

struct LogoView: View {
    enum Style {
        /// Stacked badge + wordmark (login screen)
        case full
        /// Alleen het wordmark "Underground" + "FM" (header)
        case wordmark
        /// Alleen het zwart/gele U-badge (compact)
        case mark
    }

    var style: Style = .full
    var size: CGFloat = 80

    var body: some View {
        switch style {
        case .full:
            VStack(spacing: AppSpacing.md) {
                badge
                wordmark
            }
        case .wordmark:
            wordmark
        case .mark:
            badge
        }
    }

    // MARK: - Badge (echte logo-asset met gele glow)

    private var badge: some View {
        let radius = AppRadius.md
        let borderWidth = max(2, size * 0.045)

        return Image("LogoU")
            .resizable()
            .scaledToFit()
            .padding(size * 0.18)
            .frame(width: size, height: size)
            .background(
                // Donkere/glazen vulling
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color.black.opacity(0.85))
            )
            .overlay(
                // Buitenste gele rand
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(AppColors.yellow, lineWidth: borderWidth)
            )
            .overlay(
                // Tweede, subtiele gele rand voor diepte
                RoundedRectangle(cornerRadius: radius - 3, style: .continuous)
                    .stroke(AppColors.yellow.opacity(0.25), lineWidth: 1)
                    .padding(borderWidth + 3)
            )
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .background(
                // Versterkte gele glow eronder zodat de badge lijkt te zweven
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(AppColors.yellow)
                    .blur(radius: size * 0.4)
                    .opacity(0.4)
                    .scaleEffect(0.95)
            )
    }

    // MARK: - Wordmark

    private var wordmark: some View {
        let fontSize = size * 0.28
        return HStack(spacing: 0) {
            Text("Underground")
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.yellow)
            Text("FM")
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
        }
        .tracking(-0.5)
    }
}

#Preview {
    ZStack {
        AppColors.bg.ignoresSafeArea()
        VStack(spacing: 32) {
            LogoView(style: .full, size: 96)
            LogoView(style: .wordmark, size: 80)
            LogoView(style: .mark, size: 56)
        }
    }
}
