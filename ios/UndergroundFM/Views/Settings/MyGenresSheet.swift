//
//  MyGenresSheet.swift
//  UndergroundFM
//
//  Laat een fan z'n genre-voorkeuren bijwerken. Wijzigingen werken meteen
//  door in de home-feed via AuthStore.updateGenrePreferences.
//

import SwiftUI

struct MyGenresSheet: View {
    @Environment(AuthStore.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @Bindable var l10n: L10n

    @State private var selected: Set<String> = []
    @State private var isSaving: Bool = false

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Capsule()
                .fill(AppColors.border)
                .frame(width: 40, height: 5)
                .padding(.top, AppSpacing.md)

            VStack(spacing: AppSpacing.sm) {
                Text(l10n.t("genres.title"))
                    .font(.system(size: AppFontSize.xl, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                Text(l10n.t("genres.subtitle"))
                    .font(.system(size: AppFontSize.sm, weight: .medium))
                    .foregroundStyle(AppColors.textSecond)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            ScrollView(showsIndicators: false) {
                GenrePickerGrid(selected: $selected, compact: true)
                    .padding(.top, AppSpacing.xs)
                Color.clear.frame(height: 90)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: l10n.t("settings.save"), isLoading: isSaving) {
                save()
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.md)
        }
        .onAppear {
            selected = Set(auth.currentUser?.genrePreferences ?? [])
        }
    }

    private func save() {
        isSaving = true
        Task {
            let ok = await auth.updateGenrePreferences(Array(selected))
            isSaving = false
            if ok {
                HapticManager.success()
                dismiss()
            } else {
                HapticManager.error()
            }
        }
    }
}
