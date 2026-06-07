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
        Image("logo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .background(
                // Gele glow eronder
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(AppColors.yellow)
                    .blur(radius: size * 0.35)
                    .opacity(0.25)
                    .scaleEffect(0.9)
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
