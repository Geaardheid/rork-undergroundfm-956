//
//  ProfileView.swift
//  UndergroundFM
//

import SwiftUI

struct ProfileView: View {
    @Environment(AuthStore.self) private var auth
    @Bindable var l10n: L10n
    @State private var showBecomeArtist: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // Avatar + naam
                        VStack(spacing: AppSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.card)
                                    .frame(width: 96, height: 96)
                                    .overlay(Circle().stroke(AppColors.yellow, lineWidth: 2))
                                Text(initials)
                                    .font(.system(size: 36, weight: .black, design: .rounded))
                                    .foregroundStyle(AppColors.yellow)
                            }
                            Text(displayName)
                                .font(.system(size: AppFontSize.xl, weight: .black))
                                .foregroundStyle(AppColors.textPrimary)

                            if isArtist, let artistName = auth.artistName ?? auth.currentUser?.displayName {
                                Text("\(l10n.t("artist.labelPrefix")): \(artistName)")
                                    .font(.system(size: AppFontSize.sm, weight: .bold))
                                    .foregroundStyle(AppColors.yellow)
                            }

                            HStack(spacing: AppSpacing.sm) {
                                roleBadge
                                if auth.currentUser?.isFoundingArtist == true {
                                    foundingBadge
                                }
                            }
                        }
                        .padding(.top, AppSpacing.xxl)

                        // Word artiest CTA (alleen voor fans)
                        if !isArtist {
                            becomeArtistCard
                                .padding(.horizontal, AppSpacing.lg)
                        }

                        // Settings
                        VStack(spacing: AppSpacing.sm) {
                            sectionHeader(l10n.t("settings.language"))
                            LanguagePickerButton(l10n: l10n)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, 4)
                                .background(AppColors.card)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                        }
                        .padding(.horizontal, AppSpacing.lg)

                        SecondaryButton(title: l10n.t("auth.logout")) {
                            Task { await auth.signOut() }
                        }
                        .padding(.horizontal, AppSpacing.lg)

                        Color.clear.frame(height: 120)
                    }
                }
            }
            .navigationDestination(isPresented: $showBecomeArtist) {
                BecomeArtistView(l10n: l10n)
            }
        }
    }

    private var isArtist: Bool {
        auth.currentUser?.role == .artist
    }

    private var displayName: String {
        auth.currentUser?.displayName ?? auth.currentUser?.email ?? "—"
    }

    private var initials: String {
        let name = displayName
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: AppFontSize.xs, weight: .black))
            .tracking(2)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var roleBadge: some View {
        let role = auth.currentUser?.role ?? .consumer
        let label = role == .artist ? l10n.t("role.artist") : l10n.t("role.fan")
        return HStack(spacing: 6) {
            Image(systemName: role == .artist ? "mic.fill" : "music.note")
                .font(.system(size: 12, weight: .bold))
            Text(label)
                .font(.system(size: AppFontSize.sm, weight: .bold))
        }
        .foregroundStyle(AppColors.textPrimary)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 8)
        .background(AppColors.card)
        .overlay(Capsule().stroke(AppColors.border, lineWidth: 1))
        .clipShape(Capsule())
    }

    private var foundingBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .font(.system(size: 12, weight: .black))
            Text(l10n.t("invite.foundingBadge"))
                .font(.system(size: AppFontSize.sm, weight: .black))
        }
        .foregroundStyle(AppColors.yellowText)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 8)
        .background(AppColors.yellow)
        .clipShape(Capsule())
    }

    private var becomeArtistCard: some View {
        Button {
            showBecomeArtist = true
        } label: {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(AppColors.yellow.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(AppColors.yellow)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(l10n.t("artist.becomeAction"))
                        .font(.system(size: AppFontSize.md, weight: .black))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(l10n.t("artist.becomeSubtitle"))
                        .font(.system(size: AppFontSize.sm, weight: .medium))
                        .foregroundStyle(AppColors.textSecond)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(AppColors.textMuted)
            }
            .padding(AppSpacing.lg)
            .background(AppColors.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(AppColors.yellow.opacity(0.4), lineWidth: 1)
            )
            .clipShape(.rect(cornerRadius: AppRadius.lg))
        }
        .buttonStyle(PressableScaleStyle())
    }
}
