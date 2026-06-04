//
//  SettingsSheets.swift
//  UndergroundFM
//
//  Sheets voor het instellingenscherm: wachtwoord wijzigen en account verwijderen.
//

import SwiftUI

// MARK: - Wachtwoord wijzigen

struct ChangePasswordSheet: View {
    @Environment(AuthStore.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @Bindable var l10n: L10n

    @State private var current: String = ""
    @State private var newPassword: String = ""
    @State private var isSaving: Bool = false
    @State private var errorText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Capsule()
                .fill(AppColors.border)
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, AppSpacing.md)

            Text(l10n.t("settings.changePassword"))
                .font(.system(size: AppFontSize.lg, weight: .black))
                .foregroundStyle(AppColors.textPrimary)

            secureField(placeholder: l10n.t("settings.currentPassword"), text: $current)
            secureField(placeholder: l10n.t("settings.newPassword"), text: $newPassword)

            if let errorText {
                Text(errorText)
                    .font(.system(size: AppFontSize.sm, weight: .semibold))
                    .foregroundStyle(AppColors.error)
            }

            PrimaryButton(title: l10n.t("settings.save"), isLoading: isSaving) {
                Task { await save() }
            }
            .disabled(!canSave)
            .opacity(canSave ? 1 : 0.5)

            Spacer()
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private var canSave: Bool {
        !current.isEmpty && newPassword.count >= 6
    }

    private func save() async {
        errorText = nil
        guard newPassword.count >= 6 else {
            errorText = l10n.t("errors.passwordShort")
            return
        }
        isSaving = true
        let ok = await auth.changePassword(current: current, new: newPassword)
        isSaving = false
        if ok {
            dismiss()
        } else {
            errorText = auth.errorMessage ?? l10n.t("settings.passwordWrong")
        }
    }

    private func secureField(placeholder: String, text: Binding<String>) -> some View {
        SecureField("", text: text, prompt: Text(placeholder).foregroundStyle(AppColors.textMuted))
            .textContentType(.password)
            .foregroundStyle(AppColors.textPrimary)
            .padding(AppSpacing.md)
            .background(AppColors.card)
            .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(AppColors.border, lineWidth: 1))
            .clipShape(.rect(cornerRadius: AppRadius.md))
    }
}

// MARK: - Account verwijderen

struct DeleteAccountSheet: View {
    @Environment(AuthStore.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @Bindable var l10n: L10n
    var onDeleted: () -> Void

    @State private var isDeleting: Bool = false

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Capsule()
                .fill(AppColors.border)
                .frame(width: 40, height: 5)
                .padding(.top, AppSpacing.md)

            ZStack {
                Circle().fill(AppColors.error.opacity(0.15)).frame(width: 64, height: 64)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(AppColors.error)
            }

            Text(l10n.t("settings.deleteAccount"))
                .font(.system(size: AppFontSize.lg, weight: .black))
                .foregroundStyle(AppColors.textPrimary)

            Text(l10n.t("settings.deleteWarning"))
                .font(.system(size: AppFontSize.base, weight: .medium))
                .foregroundStyle(AppColors.textSecond)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                Task { await deleteAccount() }
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    if isDeleting {
                        ProgressView().tint(.white)
                    }
                    Text(l10n.t("settings.deleteConfirm"))
                        .font(.system(size: AppFontSize.md, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(AppColors.error)
                .clipShape(.rect(cornerRadius: AppRadius.md))
            }
            .buttonStyle(PressableScaleStyle())
            .disabled(isDeleting)

            Button {
                dismiss()
            } label: {
                Text(l10n.t("common.cancel"))
                    .font(.system(size: AppFontSize.md, weight: .bold))
                    .foregroundStyle(AppColors.textSecond)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.md)
    }

    private func deleteAccount() async {
        isDeleting = true
        let ok = await auth.deleteAccount()
        isDeleting = false
        if ok {
            dismiss()
            onDeleted()
        }
    }
}
