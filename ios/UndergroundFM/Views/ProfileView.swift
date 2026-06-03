//
//  ProfileView.swift
//  UndergroundFM
//
//  Eigen profiel — fan- en artiest-variant. Publieke artiestenpagina bereikbaar
//  via tappable artiestennamen (ArtistRoute).
//

import SwiftUI

struct ProfileView: View {
    @Environment(AuthStore.self) private var auth
    @Bindable var l10n: L10n
    @State private var vm = ProfileViewModel()
    @State private var settings = AppSettings.shared

    @State private var showBecomeArtist: Bool = false
    @State private var showUpload: Bool = false
    @State private var showPhotoNotice: Bool = false
    @State private var isEditingBio: Bool = false
    @State private var editingTrack: Track?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        header

                        if isArtist {
                            artistSections
                        } else {
                            fanSections
                        }

                        settingsSection
                        logoutButton
                        Color.clear.frame(height: 120)
                    }
                    .padding(.top, AppSpacing.xxl)
                }
            }
            .navigationDestination(isPresented: $showBecomeArtist) {
                BecomeArtistView(l10n: l10n)
            }
            .navigationDestination(for: ArtistRoute.self) { route in
                ArtistProfileView(route: route, l10n: l10n)
            }
            .sheet(isPresented: $showUpload) {
                UploadTrackView(l10n: l10n)
            }
            .sheet(item: $editingTrack) { track in
                EditTrackSheet(track: track, l10n: l10n) { title, desc in
                    Task { await vm.updateTrack(track, title: title, description: desc) }
                }
                .presentationDetents([.medium])
                .presentationBackground(AppColors.bg)
            }
            .alert(l10n.t("profile.photoNoticeTitle"), isPresented: $showPhotoNotice) {
                Button(l10n.t("common.done"), role: .cancel) {}
            } message: {
                Text(l10n.t("profile.photoNoticeBody"))
            }
        }
        .task(id: taskKey) { await loadData() }
    }

    private var taskKey: String {
        "\(auth.currentUser?.id ?? "")-\(auth.artistId ?? "")"
    }

    private func loadData() async {
        guard let user = auth.currentUser else { return }
        if isArtist, let aId = auth.artistId {
            vm.bio = vm.bio
            await vm.loadArtistData(artistId: aId)
        } else {
            await vm.loadLikedTracks(userId: user.id)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: AppSpacing.md) {
            ProfileAvatar(initials: initials, photoUrl: auth.currentUser?.avatarUrl) {
                showPhotoNotice = true
            }

            VStack(spacing: 2) {
                Text(displayName)
                    .font(.system(size: AppFontSize.xl, weight: .black))
                    .foregroundStyle(AppColors.textPrimary)
                Text(auth.currentUser?.email ?? "")
                    .font(.system(size: AppFontSize.sm, weight: .medium))
                    .foregroundStyle(AppColors.textSecond)
            }

            HStack(spacing: AppSpacing.sm) {
                if isArtist, auth.currentUser?.isFoundingArtist == true {
                    FoundingBadge(label: l10n.t("invite.foundingBadge"))
                }
                if !isArtist {
                    SubscriptionBadge(
                        isActive: auth.currentUser?.hasActiveSubscription == true,
                        activeLabel: l10n.t("profile.subActive"),
                        inactiveLabel: l10n.t("profile.subInactive")
                    )
                }
            }
        }
    }

    // MARK: - Fan sections

    private var fanSections: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            ProfileSectionHeader(title: l10n.t("profile.likedTracks"))
                .padding(.horizontal, AppSpacing.lg)

            if vm.likedLoading {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.md) {
                        ForEach(0..<3, id: \.self) { _ in TrackCardSkeleton(width: 150) }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
            } else if vm.likedTracks.isEmpty {
                emptyHint(icon: "heart", text: l10n.t("profile.noLikes"))
                    .padding(.horizontal, AppSpacing.lg)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: AppSpacing.md) {
                        ForEach(vm.likedTracks) { track in
                            TrackCard(track: track, width: 150, onTap: {
                                MusicPlayer.shared.load(track: track)
                            })
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
            }

            becomeArtistCard
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
        }
    }

    // MARK: - Artist sections

    private var artistSections: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            // Bio
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    ProfileSectionHeader(title: l10n.t("artist.bioLabel"))
                    Spacer()
                    Button {
                        if isEditingBio {
                            if let aId = auth.artistId {
                                Task { await vm.saveBio(artistId: aId) }
                            }
                        }
                        isEditingBio.toggle()
                    } label: {
                        Text(isEditingBio ? l10n.t("common.done") : l10n.t("profile.edit"))
                            .font(.system(size: AppFontSize.sm, weight: .bold))
                            .foregroundStyle(AppColors.yellow)
                    }
                    .buttonStyle(.plain)
                }
                bioField
            }
            .padding(.horizontal, AppSpacing.lg)

            // Stats
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ProfileSectionHeader(title: l10n.t("stats.monthTitle"))
                StatsRow(stats: vm.stats, isLoading: vm.statsLoading, l10n: l10n)
            }
            .padding(.horizontal, AppSpacing.lg)

            // My tracks
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                ProfileSectionHeader(title: l10n.t("profile.myTracks"))
                myTracksList
                PrimaryButton(title: l10n.t("profile.uploadNew")) { showUpload = true }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }

    @ViewBuilder
    private var bioField: some View {
        if isEditingBio {
            VStack(alignment: .trailing, spacing: 4) {
                TextEditor(text: $vm.bio)
                    .scrollContentBackground(.hidden)
                    .frame(height: 100)
                    .padding(AppSpacing.sm)
                    .background(AppColors.card)
                    .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(AppColors.yellow.opacity(0.5), lineWidth: 1))
                    .clipShape(.rect(cornerRadius: AppRadius.md))
                    .foregroundStyle(AppColors.textPrimary)
                    .onChange(of: vm.bio) { _, newValue in
                        if newValue.count > 280 { vm.bio = String(newValue.prefix(280)) }
                    }
                Text("\(vm.bio.count)/280")
                    .font(.system(size: AppFontSize.xs, weight: .medium))
                    .foregroundStyle(AppColors.textMuted)
            }
        } else {
            Text(vm.bio.isEmpty ? l10n.t("profile.bioEmpty") : vm.bio)
                .font(.system(size: AppFontSize.base, weight: .medium))
                .foregroundStyle(vm.bio.isEmpty ? AppColors.textMuted : AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.md)
                .background(AppColors.card)
                .clipShape(.rect(cornerRadius: AppRadius.md))
        }
    }

    @ViewBuilder
    private var myTracksList: some View {
        if vm.tracksLoading {
            VStack(spacing: AppSpacing.sm) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .fill(AppColors.card)
                        .frame(height: 64)
                }
            }
        } else if vm.myTracks.isEmpty {
            emptyHint(icon: "music.note", text: l10n.t("profile.noTracks"))
        } else {
            VStack(spacing: AppSpacing.sm) {
                ForEach(vm.myTracks) { track in
                    SwipeToDeleteRow(deleteLabel: l10n.t("profile.delete")) {
                        await vm.deleteTrack(track)
                    } content: {
                        ArtistTrackRow(track: track)
                    }
                    .onTapGesture { editingTrack = track }
                }
            }
        }
    }

    // MARK: - Settings + logout

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ProfileSectionHeader(title: l10n.t("profile.settings"))

            HStack {
                settingsLabel(icon: "globe", text: l10n.t("settings.language"))
                Spacer()
                LanguagePickerButton(l10n: l10n)
            }
            .padding(AppSpacing.md)
            .background(AppColors.card)
            .clipShape(.rect(cornerRadius: AppRadius.md))

            HStack {
                settingsLabel(icon: "bell.fill", text: l10n.t("profile.notifications"))
                Spacer()
                Toggle("", isOn: $settings.notificationsEnabled)
                    .labelsHidden()
                    .tint(AppColors.yellow)
            }
            .padding(AppSpacing.md)
            .background(AppColors.card)
            .clipShape(.rect(cornerRadius: AppRadius.md))
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private func settingsLabel(icon: String, text: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AppColors.yellow)
                .frame(width: 22)
            Text(text)
                .font(.system(size: AppFontSize.base, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
        }
    }

    private var logoutButton: some View {
        Button {
            Task { await auth.signOut() }
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text(l10n.t("auth.logout"))
            }
            .font(.system(size: AppFontSize.md, weight: .bold))
            .foregroundStyle(AppColors.error)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(AppColors.error.opacity(0.12))
            .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(AppColors.error.opacity(0.4), lineWidth: 1))
            .clipShape(.rect(cornerRadius: AppRadius.md))
        }
        .buttonStyle(PressableScaleStyle())
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - Helpers

    private func emptyHint(icon: String, text: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(AppColors.textMuted)
            Text(text)
                .font(.system(size: AppFontSize.sm, weight: .medium))
                .foregroundStyle(AppColors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, AppSpacing.lg)
    }

    private var becomeArtistCard: some View {
        Button {
            showBecomeArtist = true
        } label: {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle().fill(AppColors.yellow.opacity(0.15)).frame(width: 44, height: 44)
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
            .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(AppColors.yellow.opacity(0.4), lineWidth: 1))
            .clipShape(.rect(cornerRadius: AppRadius.lg))
        }
        .buttonStyle(PressableScaleStyle())
    }

    private var isArtist: Bool { auth.currentUser?.role == .artist }

    private var displayName: String {
        auth.artistName ?? auth.currentUser?.displayName ?? auth.currentUser?.email ?? "—"
    }

    private var initials: String {
        let name = displayName
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}
