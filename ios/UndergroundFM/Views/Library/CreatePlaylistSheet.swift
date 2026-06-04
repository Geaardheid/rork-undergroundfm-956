//
//  CreatePlaylistSheet.swift
//  UndergroundFM
//
//  Sheet voor het aanmaken van een nieuwe playlist.
//

import SwiftUI

struct CreatePlaylistSheet: View {
    @Bindable var l10n: L10n
    let onCreated: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthStore.self) private var auth

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var isPublic: Bool = false
    @State private var isSaving: Bool = false
    @State private var errorText: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text(l10n.t("library.newPlaylist"))
                    .font(.system(size: AppFontSize.xl, weight: .black))
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.top, AppSpacing.lg)

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ProfileSectionHeader(title: l10n.t("library.nameLabel"))
                    AppTextField(
                        placeholder: l10n.t("library.namePlaceholder"),
                        text: $name,
                        autocapitalize: .sentences
                    )
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ProfileSectionHeader(title: l10n.t("library.descLabel"))
                    TextEditor(text: $description)
                        .scrollContentBackground(.hidden)
                        .frame(height: 90)
                        .padding(AppSpacing.sm)
                        .background(AppColors.card)
                        .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(AppColors.border, lineWidth: 1))
                        .clipShape(.rect(cornerRadius: AppRadius.md))
                        .foregroundStyle(AppColors.textPrimary)
                }

                Toggle(isOn: $isPublic) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(l10n.t("library.publicToggle"))
                            .font(.system(size: AppFontSize.base, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)
                        Text(l10n.t(isPublic ? "library.publicHint" : "library.privateHint"))
                            .font(.system(size: AppFontSize.sm, weight: .medium))
                            .foregroundStyle(AppColors.textSecond)
                    }
                }
                .tint(AppColors.yellow)
                .padding(AppSpacing.md)
                .background(AppColors.card)
                .clipShape(.rect(cornerRadius: AppRadius.md))

                if let errorText {
                    Text(errorText)
                        .font(.system(size: AppFontSize.sm, weight: .semibold))
                        .foregroundStyle(AppColors.error)
                }

                PrimaryButton(
                    title: l10n.t("library.createButton"),
                    isLoading: isSaving,
                    isDisabled: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    Task { await create() }
                }

                SecondaryButton(title: l10n.t("common.cancel")) {
                    dismiss()
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }

    private func create() async {
        guard let userId = auth.currentUser?.id, !isSaving else { return }
        isSaving = true
        errorText = nil
        do {
            try await PlaylistService.shared.createPlaylist(
                userId: userId,
                name: name,
                description: description,
                isPublic: isPublic
            )
            await onCreated()
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
        isSaving = false
    }
}
