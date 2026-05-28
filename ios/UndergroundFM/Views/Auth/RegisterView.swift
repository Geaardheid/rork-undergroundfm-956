//
//  RegisterView.swift
//  UndergroundFM
//

import SwiftUI

private enum RegisterStep {
    case details
    case inviteCode
}

struct RegisterView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @Bindable var l10n: L10n

    @State private var step: RegisterStep = .details
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var displayName: String = ""
    @State private var isArtist: Bool = false
    @State private var inviteCode: String = ""

    var body: some View {
        ZStack {
            AppColors.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        switch step {
                        case .details:
                            detailsForm
                        case .inviteCode:
                            inviteForm
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.xxxl)
                }
            }
        }
        .onAppear { auth.clearError() }
    }

    private var header: some View {
        HStack {
            Button {
                if step == .inviteCode {
                    step = .details
                    auth.clearError()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            Text(l10n.t("auth.register"))
                .font(.system(size: AppFontSize.md, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.top, AppSpacing.sm)
    }

    // MARK: - Step 1

    private var detailsForm: some View {
        VStack(spacing: AppSpacing.md) {
            LogoView(size: 64)
                .padding(.bottom, AppSpacing.md)

            AppTextField(
                placeholder: l10n.t("auth.displayName"),
                text: $displayName,
                autocapitalize: .words,
                contentType: .name
            )
            AppTextField(
                placeholder: l10n.t("auth.email"),
                text: $email,
                keyboard: .emailAddress,
                contentType: .emailAddress
            )
            AppTextField(
                placeholder: l10n.t("auth.password"),
                text: $password,
                isSecure: true,
                contentType: .newPassword
            )

            // Rol selector
            Text(l10n.t("role.choose"))
                .font(.system(size: AppFontSize.sm, weight: .semibold))
                .foregroundStyle(AppColors.textSecond)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, AppSpacing.md)

            HStack(spacing: AppSpacing.md) {
                roleCard(title: l10n.t("role.fan"), icon: "music.note", selected: !isArtist) {
                    isArtist = false
                }
                roleCard(title: l10n.t("role.artist"), icon: "mic.fill", selected: isArtist) {
                    isArtist = true
                }
            }

            if let err = auth.errorMessage {
                Text(err)
                    .font(.system(size: AppFontSize.sm, weight: .medium))
                    .foregroundStyle(AppColors.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton(
                title: l10n.t("auth.continue"),
                isLoading: auth.isLoading,
                isDisabled: !canContinueStep1
            ) {
                if isArtist {
                    auth.clearError()
                    step = .inviteCode
                } else {
                    Task {
                        await auth.signUpFan(
                            email: email.trimmingCharacters(in: .whitespaces),
                            password: password,
                            displayName: displayName.trimmingCharacters(in: .whitespaces)
                        )
                    }
                }
            }
            .padding(.top, AppSpacing.md)
        }
    }

    private func roleCard(title: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(selected ? AppColors.yellow : AppColors.textSecond)
                Text(title)
                    .font(.system(size: AppFontSize.sm, weight: .semibold))
                    .foregroundStyle(selected ? AppColors.textPrimary : AppColors.textSecond)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(AppColors.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(selected ? AppColors.yellow : AppColors.border, lineWidth: selected ? 2 : 1)
            )
            .clipShape(.rect(cornerRadius: AppRadius.md))
        }
        .buttonStyle(PressableScaleStyle())
    }

    // MARK: - Step 2

    private var inviteForm: some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "key.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(AppColors.yellow)
                Text(l10n.t("invite.title"))
                    .font(.system(size: AppFontSize.xl, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                Text(l10n.t("invite.subtitle"))
                    .font(.system(size: AppFontSize.sm))
                    .foregroundStyle(AppColors.textSecond)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.md)
            }
            .padding(.top, AppSpacing.lg)

            InviteCodeInputView(code: $inviteCode)
                .padding(.top, AppSpacing.md)

            if inviteCode.uppercased().hasPrefix("FOUND") && inviteCode.count >= 5 {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(AppColors.yellowText)
                    Text(l10n.t("invite.foundingBadge"))
                        .font(.system(size: AppFontSize.sm, weight: .black))
                        .foregroundStyle(AppColors.yellowText)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 6)
                .background(AppColors.yellow)
                .clipShape(Capsule())
            }

            if let err = auth.errorMessage {
                Text(err)
                    .font(.system(size: AppFontSize.sm, weight: .medium))
                    .foregroundStyle(AppColors.error)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            PrimaryButton(
                title: l10n.t("invite.verify"),
                isLoading: auth.isLoading,
                isDisabled: inviteCode.count < 4
            ) {
                Task {
                    await auth.signUpArtist(
                        email: email.trimmingCharacters(in: .whitespaces),
                        password: password,
                        displayName: displayName.trimmingCharacters(in: .whitespaces),
                        inviteCode: inviteCode
                    )
                }
            }
        }
    }

    private var canContinueStep1: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@") &&
        password.count >= 6
    }
}
