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

    // MARK: - Badge (zwart vierkant + geel italic U)

    private var badge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppColors.bg)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .stroke(AppColors.yellow, lineWidth: max(2, size * 0.045))
                )

            // Innerlijke schaduw via tweede stroke (subtiel)
            RoundedRectangle(cornerRadius: AppRadius.md - 2, style: .continuous)
                .stroke(AppColors.yellow.opacity(0.25), lineWidth: 1)
                .padding(max(3, size * 0.06))

            Text("U")
                .font(.system(size: size * 0.6, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.yellow)
                .italic()
                .offset(x: -size * 0.015)
        }
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
