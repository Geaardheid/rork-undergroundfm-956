//
//  OnboardingView.swift
//  UndergroundFM
//
//  First-launch welcome flow. Shown once, then never again.
//

import SwiftUI

struct OnboardingView: View {
    @Bindable var l10n: L10n
    /// Called when the user chooses "Inloggen" — finishes onboarding and goes to login.
    let onLogin: () -> Void
    /// Called when the user chooses "Registreren" — finishes onboarding and opens register.
    /// Bool = whether the artist role was selected on slide 2.
    let onRegister: (Bool) -> Void

    @State private var page: Int = 0
    @State private var isArtist: Bool = false

    private let lastPage: Int = 2

    var body: some View {
        ZStack {
            AppColors.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    slide1.tag(0)
                    slide2.tag(1)
                    slide3.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: page)

                bottomBar
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.lg)
            }
        }
    }

    // MARK: - Bottom bar (dots + Volgende)

    private var bottomBar: some View {
        ZStack {
            dots
            HStack {
                Spacer()
                if page < lastPage {
                    nextButton
                }
            }
        }
        .frame(height: 52)
    }

    private var dots: some View {
        HStack(spacing: 8) {
            ForEach(0...lastPage, id: \.self) { i in
                Capsule()
                    .fill(i == page ? AppColors.yellow : AppColors.border)
                    .frame(width: i == page ? 22 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: page)
            }
        }
    }

    private var nextButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                page = min(page + 1, lastPage)
            }
        } label: {
            HStack(spacing: 6) {
                Text(l10n.t("onb.next"))
                    .font(.system(size: AppFontSize.base, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(AppColors.yellowText)
            .padding(.horizontal, AppSpacing.lg)
            .frame(height: 48)
            .background(AppColors.yellow)
            .clipShape(Capsule())
        }
        .buttonStyle(PressableScaleStyle())
    }

    // MARK: - Slide 1 — Alleen Underground

    private var slide1: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Spacer()

            VStack(alignment: .leading, spacing: -6) {
                Text(l10n.t("onb.s1.line1"))
                    .foregroundStyle(AppColors.textPrimary)
                Text(l10n.t("onb.s1.line2"))
                    .foregroundStyle(AppColors.yellow)
            }
            .font(.system(size: 52, weight: .black, design: .rounded))
            .tracking(-1)
            .lineLimit(1)
            .minimumScaleFactor(0.5)

            Text(l10n.t("onb.s1.subtitle"))
                .font(.system(size: AppFontSize.md, weight: .medium))
                .foregroundStyle(AppColors.textSecond)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, AppSpacing.xs)

            statBadges
                .padding(.top, AppSpacing.md)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.xl)
    }

    private var statBadges: some View {
        let items = [
            l10n.t("onb.s1.stat1"),
            l10n.t("onb.s1.stat2"),
            l10n.t("onb.s1.stat3"),
            l10n.t("onb.s1.stat4")
        ]
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.system(size: AppFontSize.sm, weight: .bold))
                        .foregroundStyle(AppColors.yellow)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColors.yellow.opacity(0.12))
                        .overlay(
                            Capsule().stroke(AppColors.yellow.opacity(0.5), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Slide 2 — Kies je rol

    private var slide2: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            Text(l10n.t("onb.s2.title"))
                .font(.system(size: AppFontSize.xxl, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: AppSpacing.lg) {
                roleCard(
                    emoji: "🎧",
                    title: l10n.t("role.fan"),
                    hint: l10n.t("onb.s2.fanHint"),
                    selected: !isArtist
                ) { isArtist = false }

                roleCard(
                    emoji: "🎤",
                    title: l10n.t("role.artist"),
                    hint: l10n.t("onb.s2.artistHint"),
                    selected: isArtist
                ) { isArtist = true }
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, AppSpacing.xl)
    }

    private func roleCard(emoji: String, title: String, hint: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Text(emoji)
                    .font(.system(size: 36))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: AppFontSize.lg, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(hint)
                        .font(.system(size: AppFontSize.xs, weight: .medium))
                        .foregroundStyle(AppColors.textSecond)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(selected ? AppColors.yellow : AppColors.border)
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? AppColors.yellow.opacity(0.10) : AppColors.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(selected ? AppColors.yellow : AppColors.border, lineWidth: selected ? 2 : 1)
            )
            .clipShape(.rect(cornerRadius: AppRadius.lg))
        }
        .buttonStyle(PressableScaleStyle())
    }

    // MARK: - Slide 3 — Aan de slag

    private var slide3: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Text(l10n.t("onb.s3.badge"))
                .font(.system(size: AppFontSize.xs, weight: .black))
                .tracking(1)
                .foregroundStyle(AppColors.yellowText)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 6)
                .background(AppColors.yellow)
                .clipShape(Capsule())

            Text(l10n.t("onb.s3.title"))
                .font(.system(size: AppFontSize.hero, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(l10n.t("onb.s3.subtitle"))
                .font(.system(size: AppFontSize.md, weight: .medium))
                .foregroundStyle(AppColors.textSecond)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, AppSpacing.md)

            Spacer()

            PrimaryButton(title: l10n.t("auth.register")) {
                onRegister(isArtist)
            }

            Button {
                onLogin()
            } label: {
                Text("\(l10n.t("auth.hasAccount")) \(l10n.t("auth.login"))")
                    .font(.system(size: AppFontSize.base, weight: .semibold))
                    .foregroundStyle(AppColors.textSecond)
            }
            .padding(.top, AppSpacing.xs)

            Spacer()
        }
        .padding(.horizontal, AppSpacing.xl)
    }
}
