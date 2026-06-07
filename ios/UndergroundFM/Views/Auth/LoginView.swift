//
//  LoginView.swift
//  UndergroundFM
//

import SwiftUI

struct LoginView: View {
    @Environment(AuthStore.self) private var auth
    @Bindable var l10n: L10n

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showRegister: Bool = false

    var body: some View {
        ZStack {
            CinematicBackground()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Spacer()
                    LanguagePickerButton(l10n: l10n)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)

                Spacer()

                // Logo
                LogoView(style: .full, size: 88)

                Text(l10n.t("app.tagline"))
                    .font(.system(size: AppFontSize.sm, weight: .medium))
                    .foregroundStyle(AppColors.textSecond)
                    .multilineTextAlignment(.center)
                    .padding(.top, AppSpacing.md)
                    .padding(.horizontal, AppSpacing.xl)

                Spacer().frame(height: AppSpacing.xxxl)

                // Form — subtle dark layer behind the fields for readability.
                VStack(spacing: AppSpacing.md) {
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
                        contentType: .password
                    )

                    if let err = auth.errorMessage {
                        Text(err)
                            .font(.system(size: AppFontSize.sm, weight: .medium))
                            .foregroundStyle(AppColors.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, AppSpacing.xs)
                    }

                    PrimaryButton(
                        title: l10n.t("auth.login"),
                        isLoading: auth.isLoading,
                        isDisabled: !canSubmit
                    ) {
                        Task { await auth.signIn(email: email.trimmingCharacters(in: .whitespaces), password: password) }
                    }
                    .padding(.top, AppSpacing.sm)
                }
                .padding(AppSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .fill(.black.opacity(0.35))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .stroke(AppColors.border.opacity(0.4), lineWidth: 1)
                )
                .padding(.horizontal, AppSpacing.lg)

                Spacer()

                // Footer
                HStack(spacing: 6) {
                    Text(l10n.t("auth.noAccount"))
                        .font(.system(size: AppFontSize.base))
                        .foregroundStyle(AppColors.textSecond)
                    Button {
                        auth.clearError()
                        showRegister = true
                    } label: {
                        Text(l10n.t("auth.register"))
                            .font(.system(size: AppFontSize.base, weight: .bold))
                            .foregroundStyle(AppColors.yellow)
                    }
                }
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .sheet(isPresented: $showRegister) {
            RegisterView(l10n: l10n)
                .presentationBackground(AppColors.bg)
        }
    }

    private var canSubmit: Bool {
        !email.isEmpty && password.count >= 6
    }
}
