//
//  PaywallView.swift
//  UndergroundFM
//
//  Paywall voor niet-abonnees. Spotify-model: betalen gebeurt via een web Payment
//  Link (0% Apple-cut). Deze view bevat GEEN in-app purchase. Na betalen op het web
//  kan de gebruiker terugkeren en "Ik heb betaald — ververs" tikken; dat roept
//  SubscriptionService.refresh() aan en ontgrendelt zonder re-login.
//

import SwiftUI

struct PaywallView: View {
    @Environment(SubscriptionService.self) private var subscription
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @Bindable var l10n: L10n

    @State private var isRefreshing: Bool = false

    private let perks: [(icon: String, key: String)] = [
        ("infinity", "paywall.perkUnlimited"),
        ("waveform", "paywall.perkQuality"),
        ("heart.fill", "paywall.perkSupport"),
        ("bolt.fill", "paywall.perkEarly")
    ]

    var body: some View {
        ZStack {
            AppColors.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppSpacing.xl) {
                    closeRow
                    hero
                    perksList
                    Spacer(minLength: AppSpacing.lg)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, 140)
            }

            VStack(spacing: 0) {
                Spacer()
                ctaBlock
            }
        }
    }

    // MARK: - Close

    private var closeRow: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(AppColors.textSecond)
                    .frame(width: 36, height: 36)
                    .background(AppColors.card)
                    .clipShape(Circle())
            }
            .buttonStyle(PressableScaleStyle())
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: AppSpacing.lg) {
            ZStack {
                Circle()
                    .fill(AppColors.yellow.opacity(0.12))
                    .frame(width: 132, height: 132)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 56, weight: .black))
                    .foregroundStyle(AppColors.yellow)
                    .shadow(color: AppColors.yellow.opacity(0.6), radius: 24)
            }

            VStack(spacing: AppSpacing.sm) {
                Text(l10n.t("paywall.title"))
                    .font(.system(size: AppFontSize.xxl, weight: .black))
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(l10n.t("paywall.subtitle"))
                    .font(.system(size: AppFontSize.base, weight: .medium))
                    .foregroundStyle(AppColors.textSecond)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Perks

    private var perksList: some View {
        VStack(spacing: AppSpacing.md) {
            ForEach(perks, id: \.key) { perk in
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: perk.icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColors.yellow)
                        .frame(width: 40, height: 40)
                        .background(AppColors.card)
                        .clipShape(.rect(cornerRadius: AppRadius.md))

                    Text(l10n.t(perk.key))
                        .font(.system(size: AppFontSize.base, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)

                    Spacer(minLength: 0)
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.card.opacity(0.4))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .clipShape(.rect(cornerRadius: AppRadius.lg))
    }

    // MARK: - CTA

    private var ctaBlock: some View {
        VStack(spacing: AppSpacing.md) {
            PrimaryButton(title: l10n.t("paywall.cta")) {
                subscription.openPaymentLink { openURL($0) }
            }

            Button {
                Task { await refreshStatus() }
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    if isRefreshing {
                        ProgressView().tint(AppColors.yellow)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .bold))
                    }
                    Text(l10n.t("paywall.refresh"))
                        .font(.system(size: AppFontSize.sm, weight: .bold))
                }
                .foregroundStyle(AppColors.yellow)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
            .buttonStyle(PressableScaleStyle())
            .disabled(isRefreshing)

            Text(l10n.t("paywall.webNotice"))
                .font(.system(size: AppFontSize.xs, weight: .medium))
                .foregroundStyle(AppColors.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.xl)
        .background(
            LinearGradient(
                colors: [AppColors.bg.opacity(0), AppColors.bg, AppColors.bg],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private func refreshStatus() async {
        isRefreshing = true
        let nowSubscribed = await subscription.refresh()
        isRefreshing = false
        if nowSubscribed {
            dismiss()
        }
    }
}
