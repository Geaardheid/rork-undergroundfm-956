//
//  SettingsView.swift
//  UndergroundFM
//
//  Instellingenscherm — bereikbaar via het tandwiel in de profielheader.
//  Secties: Account, Audio, Notificaties, Over, Sessie.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(SubscriptionService.self) private var subscription
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @Bindable var l10n: L10n
    @State private var settings = AppSettings.shared

    @State private var followedArtists: [ArtistProfile] = []
    @State private var loadingArtists: Bool = true

    @State private var showChangePassword: Bool = false
    @State private var showDeleteAccount: Bool = false
    @State private var showPrivacy: Bool = false
    @State private var showTerms: Bool = false
    @State private var showGenres: Bool = false

    var body: some View {
        ZStack {
            AppColors.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    subscriptionSection
                    if auth.currentUser?.role != .artist {
                        genresSection
                    }
                    accountSection
                    audioSection
                    notificationsSection
                    aboutSection
                    sessionSection
                    Color.clear.frame(height: 40)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
            }
        }
        .navigationTitle(l10n.t("settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.headerBg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordSheet(l10n: l10n)
                .presentationDetents([.medium])
                .presentationBackground(AppColors.bg)
        }
        .sheet(isPresented: $showDeleteAccount) {
            DeleteAccountSheet(l10n: l10n) { dismiss() }
                .presentationDetents([.medium])
                .presentationBackground(AppColors.bg)
        }
        .sheet(isPresented: $showPrivacy) {
            PlaceholderSheet(title: l10n.t("settings.privacy"), message: l10n.t("settings.privacyBody"))
                .presentationDetents([.medium])
                .presentationBackground(AppColors.bg)
        }
        .sheet(isPresented: $showTerms) {
            PlaceholderSheet(title: l10n.t("settings.terms"), message: l10n.t("settings.termsBody"))
                .presentationDetents([.medium])
                .presentationBackground(AppColors.bg)
        }
        .sheet(isPresented: $showGenres) {
            MyGenresSheet(l10n: l10n)
                .presentationDetents([.large])
                .presentationBackground(AppColors.bg)
        }
        .task { await loadFollowedArtists() }
    }

    // MARK: - Abonnement

    @ViewBuilder
    private var subscriptionSection: some View {
        SettingsSection(title: l10n.t("settings.subSection")) {
            if auth.currentUser?.role == .artist {
                subscriptionRow(
                    icon: "checkmark.seal.fill",
                    title: l10n.t("settings.subArtist"),
                    subtitle: l10n.t("settings.subArtistHint")
                )
            } else if subscription.isSubscribed {
                subscriptionRow(
                    icon: "bolt.fill",
                    title: "\(l10n.t("settings.subStatus")): \(l10n.t("settings.subActive"))"
                )
                SettingsDivider()
                SettingsRow(icon: "creditcard.fill", title: l10n.t("settings.subManage")) {
                    Task { await subscription.openManageSubscription { openURL($0) } }
                }
            } else {
                subscriptionRow(
                    icon: "lock.fill",
                    title: "\(l10n.t("settings.subStatus")): \(l10n.t("settings.subInactive"))"
                )
                SettingsDivider()
                SettingsRow(icon: "star.fill", title: l10n.t("settings.subJoin")) {
                    subscription.showPaywall = true
                }
            }
        }
    }

    @ViewBuilder
    private func subscriptionRow(icon: String, title: String, subtitle: String? = nil) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColors.yellow)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: AppFontSize.base, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: AppFontSize.sm, weight: .medium))
                        .foregroundStyle(AppColors.textMuted)
                }
            }
            Spacer()
        }
        .padding(AppSpacing.md)
    }

    // MARK: - Genres

    private var genresSection: some View {
        SettingsSection(title: l10n.t("settings.sectionGenres")) {
            SettingsRow(icon: "music.note.list", title: l10n.t("settings.myGenres")) {
                showGenres = true
            }
        }
    }

    // MARK: - Account

    private var accountSection: some View {
        SettingsSection(title: l10n.t("settings.sectionAccount")) {
            SettingsRow(icon: "key.fill", title: l10n.t("settings.changePassword")) {
                showChangePassword = true
            }
            SettingsDivider()
            SettingsRow(icon: "trash.fill", title: l10n.t("settings.deleteAccount"), tint: AppColors.error) {
                showDeleteAccount = true
            }
        }
    }

    // MARK: - Audio

    private var audioSection: some View {
        SettingsSection(title: l10n.t("settings.sectionAudio")) {
            ForEach(Array(AudioQuality.allCases.enumerated()), id: \.element.id) { index, quality in
                if index > 0 { SettingsDivider() }
                Button {
                    settings.audioQuality = quality
                } label: {
                    HStack(spacing: AppSpacing.md) {
                        Text(qualityLabel(quality))
                            .font(.system(size: AppFontSize.base, weight: .semibold))
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        if settings.audioQuality == quality {
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .black))
                                .foregroundStyle(AppColors.yellow)
                        }
                    }
                    .padding(AppSpacing.md)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func qualityLabel(_ q: AudioQuality) -> String {
        switch q {
        case .high: return l10n.t("settings.qualityHigh")
        case .normal: return l10n.t("settings.qualityNormal")
        case .low: return l10n.t("settings.qualityLow")
        }
    }

    // MARK: - Notificaties

    private var notificationsSection: some View {
        SettingsSection(title: l10n.t("settings.sectionNotifications")) {
            if loadingArtists {
                HStack {
                    ProgressView().tint(AppColors.yellow)
                    Text(l10n.t("common.loading"))
                        .font(.system(size: AppFontSize.sm, weight: .medium))
                        .foregroundStyle(AppColors.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.md)
            } else if followedArtists.isEmpty {
                Text(l10n.t("settings.noFollows"))
                    .font(.system(size: AppFontSize.sm, weight: .medium))
                    .foregroundStyle(AppColors.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppSpacing.md)
            } else {
                ForEach(Array(followedArtists.enumerated()), id: \.element.id) { index, artist in
                    if index > 0 { SettingsDivider() }
                    ArtistNotificationToggle(artist: artist, settings: settings, l10n: l10n)
                }
            }
        }
    }

    // MARK: - Over

    private var aboutSection: some View {
        SettingsSection(title: l10n.t("settings.sectionAbout")) {
            SettingsRow(icon: "hand.raised.fill", title: l10n.t("settings.privacy")) {
                showPrivacy = true
            }
            SettingsDivider()
            SettingsRow(icon: "doc.text.fill", title: l10n.t("settings.terms")) {
                showTerms = true
            }
            SettingsDivider()
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.yellow)
                    .frame(width: 24)
                Text(l10n.t("settings.version"))
                    .font(.system(size: AppFontSize.base, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Text(appVersion)
                    .font(.system(size: AppFontSize.sm, weight: .medium))
                    .foregroundStyle(AppColors.textMuted)
            }
            .padding(AppSpacing.md)
        }
    }

    // MARK: - Sessie

    private var sessionSection: some View {
        SettingsSection(title: l10n.t("settings.sectionSession")) {
            Button {
                Task { await auth.signOut() }
            } label: {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColors.error)
                        .frame(width: 24)
                    Text(l10n.t("auth.logout"))
                        .font(.system(size: AppFontSize.base, weight: .bold))
                        .foregroundStyle(AppColors.error)
                    Spacer()
                }
                .padding(AppSpacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(v) (\(b))"
    }

    private func loadFollowedArtists() async {
        guard let userId = auth.currentUser?.id else {
            loadingArtists = false
            return
        }
        followedArtists = (try? await FollowService.shared.fetchFollowedArtists(userId: userId)) ?? []
        loadingArtists = false
    }
}

// MARK: - Section container

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ProfileSectionHeader(title: title)
                .padding(.horizontal, AppSpacing.xs)
            VStack(spacing: 0) {
                content()
            }
            .background(AppColors.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .clipShape(.rect(cornerRadius: AppRadius.md))
        }
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    var tint: Color = AppColors.yellow
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: AppFontSize.base, weight: .semibold))
                    .foregroundStyle(tint == AppColors.error ? AppColors.error : AppColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppColors.textMuted)
            }
            .padding(AppSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(AppColors.border)
            .frame(height: 1)
            .padding(.leading, AppSpacing.md)
    }
}

// MARK: - Artist notification toggle

private struct ArtistNotificationToggle: View {
    let artist: ArtistProfile
    @Bindable var settings: AppSettings
    @Bindable var l10n: L10n

    var body: some View {
        let binding = Binding<Bool>(
            get: { settings.isArtistNotificationOn(artist.id) },
            set: { settings.setArtistNotification(artist.id, $0) }
        )
        Toggle(isOn: binding) {
            Text(l10n.t("settings.newUploadsFrom").replacingOccurrences(of: "%@", with: artist.artistName))
                .font(.system(size: AppFontSize.base, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)
        }
        .tint(AppColors.yellow)
        .padding(AppSpacing.md)
    }
}

// MARK: - Placeholder sheet (Privacy / Terms)

private struct PlaceholderSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Capsule()
                .fill(AppColors.border)
                .frame(width: 40, height: 5)
                .padding(.top, AppSpacing.md)

            Text(title)
                .font(.system(size: AppFontSize.lg, weight: .black))
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(message)
                .font(.system(size: AppFontSize.base, weight: .medium))
                .foregroundStyle(AppColors.textSecond)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .padding(.horizontal, AppSpacing.lg)
    }
}
