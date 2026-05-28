//
//  ComingSoonView.swift
//  UndergroundFM
//

import SwiftUI

struct ComingSoonView: View {
    @Bindable var l10n: L10n
    let titleKey: String
    let icon: String

    var body: some View {
        ZStack {
            AppColors.bg.ignoresSafeArea()
            VStack(spacing: AppSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(AppColors.yellow.opacity(0.1))
                        .frame(width: 120, height: 120)
                    Image(systemName: icon)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(AppColors.yellow)
                }
                Text(l10n.t(titleKey))
                    .font(.system(size: AppFontSize.xxl, weight: .black))
                    .foregroundStyle(AppColors.textPrimary)
                Text(l10n.t("common.comingSoon"))
                    .font(.system(size: AppFontSize.sm, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(AppColors.textMuted)
                    .textCase(.uppercase)
            }
        }
    }
}
