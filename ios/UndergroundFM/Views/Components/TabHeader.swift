//
//  TabHeader.swift
//  UndergroundFM
//
//  Gedeelde header-stijl voor alle tabs zodat de app één samenhangend product voelt:
//  zwarte achtergrond (#141414), vette titel en een dunne gele lijn met zachte glow.
//

import SwiftUI

/// Sticky header-balk die op elke tab dezelfde uitstraling geeft.
/// Geef eigen content mee (bijv. logo + iconen op Home) of gebruik `TabHeader(title:)`.
struct TabHeader<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TabHeaderBackground())
            .overlay(alignment: .bottom) { HeaderGlowLine() }
    }
}

extension TabHeader where Content == HeaderTitle {
    /// Gemaksinitializer voor tabs met een simpele tekst-titel.
    init(title: String) {
        self.init { HeaderTitle(title: title) }
    }
}

/// Standaard titel-rij: vette witte titel, links uitgelijnd.
struct HeaderTitle: View {
    let title: String

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: AppFontSize.xl, weight: .black))
                .foregroundStyle(AppColors.textPrimary)
            Spacer(minLength: 0)
        }
    }
}

/// Gedeelde header-achtergrond: liquid glass op iOS 26, anders een donkere kaartlaag
/// met subtiele rand, getint naar #141414.
struct TabHeaderBackground: View {
    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                Rectangle()
                    .fill(.clear)
                    .glassEffect(.regular, in: Rectangle())
                    .overlay(Rectangle().fill(AppColors.headerBg.opacity(0.5)))
            } else {
                Rectangle()
                    .fill(AppColors.headerBg.opacity(0.88))
                    .background(.ultraThinMaterial)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.border.opacity(0.6))
                .frame(height: 0.5)
        }
    }
}

/// Dunne gele lijn met zachte glow onder de header.
struct HeaderGlowLine: View {
    var body: some View {
        Rectangle()
            .fill(AppColors.yellow)
            .frame(height: 2)
            .shadow(color: AppColors.yellow, radius: 8)
            .shadow(color: AppColors.yellow.opacity(0.6), radius: 4)
    }
}
