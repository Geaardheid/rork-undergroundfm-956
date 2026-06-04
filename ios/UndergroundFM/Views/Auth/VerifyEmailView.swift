//
//  VerifyEmailView.swift
//  UndergroundFM
//
//  Getoond na registratie wanneer de e-mail nog bevestigd moet worden.
//  Controleert automatisch op bevestiging zodra de app weer actief wordt
//  (scenePhase) of via de deep link undergroundfm://auth/callback.
//

import SwiftUI

struct VerifyEmailView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(\.scenePhase) private var scenePhase
    @Bindable var l10n: L10n

    @State private var didTapCheck: Bool = false

    var body: some View {
        ZStack {
            AppColors.bg.ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(AppColors.yellow.opacity(0.12))
                        .frame(width: 120, height: 120)
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(AppColors.yellow)
                }

                VStack(spacing: AppSpacing.md) {
                    Text("Bevestig je e-mail")
                        .font(.system(size: AppFontSize.xxl, weight: .black))
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .font(.system(size: AppFontSize.base, weight: .medium))
                        .foregroundStyle(AppColors.textSecond)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.lg)

                    if let email = auth.pendingEmail {
                        Text(email)
                            .font(.system(size: AppFontSize.md, weight: .bold))
                            .foregroundStyle(AppColors.yellow)
                            .multilineTextAlignment(.center)
                            .padding(.top, AppSpacing.xs)
                    }
                }

                if didTapCheck && auth.awaitingConfirmation && !auth.isLoading {
                    Text("Nog niet bevestigd. Open de link in je e-mail en kom terug.")
                        .font(.system(size: AppFontSize.sm, weight: .medium))
                        .foregroundStyle(AppColors.warning)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.lg)
                        .transition(.opacity)
                }

                Spacer()

                VStack(spacing: AppSpacing.md) {
                    PrimaryButton(
                        title: "Ik heb mijn e-mail bevestigd",
                        isLoading: auth.isLoading
                    ) {
                        checkConfirmation()
                    }

                    Button {
                        auth.cancelPendingConfirmation()
                    } label: {
                        Text("Terug naar inloggen")
                            .font(.system(size: AppFontSize.base, weight: .bold))
                            .foregroundStyle(AppColors.textSecond)
                    }
                    .padding(.top, AppSpacing.xs)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: didTapCheck)
        .onChange(of: scenePhase) { _, newPhase in
            // Terug op de voorgrond na het bevestigen in de mailclient → check.
            if newPhase == .active && auth.awaitingConfirmation {
                Task { await auth.restoreSession() }
            }
        }
    }

    private var subtitle: String {
        "We hebben een verificatielink gestuurd naar je inbox. Tik op de link en kom terug naar de app."
    }

    private func checkConfirmation() {
        didTapCheck = true
        Task { await auth.restoreSession() }
    }
}
