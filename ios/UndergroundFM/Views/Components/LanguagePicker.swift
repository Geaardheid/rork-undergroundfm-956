//
//  LanguagePicker.swift
//  UndergroundFM
//

import SwiftUI

struct LanguagePickerButton: View {
    @Bindable var l10n: L10n
    @State private var showSheet = false

    var body: some View {
        Button {
            showSheet = true
        } label: {
            HStack(spacing: 6) {
                Text(l10n.language.flag)
                    .font(.system(size: 16))
                Text(l10n.language.rawValue.uppercased())
                    .font(.system(size: AppFontSize.sm, weight: .semibold))
                    .foregroundStyle(AppColors.textSecond)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 8)
            .background(AppColors.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .clipShape(.rect(cornerRadius: AppRadius.sm))
        }
        .sheet(isPresented: $showSheet) {
            LanguagePickerSheet(l10n: l10n)
                .presentationDetents([.height(320)])
                .presentationBackground(AppColors.bg)
        }
    }
}

struct LanguagePickerSheet: View {
    @Bindable var l10n: L10n
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Text(l10n.t("settings.language"))
                .font(.system(size: AppFontSize.lg, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, AppSpacing.lg)

            VStack(spacing: AppSpacing.sm) {
                ForEach(AppLanguage.allCases) { lang in
                    Button {
                        l10n.setLanguage(lang)
                        dismiss()
                    } label: {
                        HStack(spacing: AppSpacing.md) {
                            Text(lang.flag).font(.system(size: 28))
                            Text(lang.displayName)
                                .font(.system(size: AppFontSize.md, weight: .semibold))
                                .foregroundStyle(AppColors.textPrimary)
                            Spacer()
                            if l10n.language == lang {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppColors.yellow)
                                    .font(.system(size: 22))
                            }
                        }
                        .padding(AppSpacing.lg)
                        .background(AppColors.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md)
                                .stroke(l10n.language == lang ? AppColors.yellow : AppColors.border, lineWidth: l10n.language == lang ? 1.5 : 1)
                        )
                        .clipShape(.rect(cornerRadius: AppRadius.md))
                    }
                    .buttonStyle(PressableScaleStyle())
                }
            }

            Spacer()
        }
        .padding(.horizontal, AppSpacing.lg)
    }
}
