//
//  ArtistProfileView.swift
//  UndergroundFM
//
//  Publieke artiestenpagina — zichtbaar voor fans die op een artiestennaam tikken.
//

import SwiftUI

struct ArtistProfileView: View {
    let route: ArtistRoute
    @Bindable var l10n: L10n
    @Environment(AuthStore.self) private var auth

    @State private var profile: ArtistProfile?
    @State private var tracks: [Track] = []
    @State private var stats: ArtistMonthStats = .empty
    @State private var isLoading: Bool = true
    @State private var statsLoading: Bool = true
    @State private var isFollowing: Bool = false
    @State private var followBusy: Bool = false

    var body: some View {
        ZStack {
            AppColors.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    header
                    StatsRow(stats: stats, isLoading: statsLoading, l10n: l10n)
                        .padding(.horizontal, AppSpacing.lg)
                    followButton
                        .padding(.horizontal, AppSpacing.lg)
                    tracksSection
                    Color.clear.frame(height: 120)
                }
                .padding(.top, AppSpacing.lg)
            }
        }
        .navigationTitle(route.artistName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.bg, for: .navigationBar)
        .task { await load() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: AppSpacing.md) {
            ProfileAvatar(initials: initials, photoUrl: profile?.avatarUrl, size: 100)

            Text(profile?.artistName ?? route.artistName)
                .font(.system(size: AppFontSize.xxl, weight: .black))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            if profile?.isFoundingArtist == true {
                FoundingBadge(label: l10n.t("invite.foundingBadge"))
            }

            if let bio = profile?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: AppFontSize.base, weight: .medium))
                    .foregroundStyle(AppColors.textSecond)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }

            if let tags = profile?.genreTags, !tags.isEmpty {
                GenreTagsRow(tags: tags)
                    .padding(.horizontal, AppSpacing.lg)
            }
        }
    }

    // MARK: - Follow

    private var followButton: some View {
        Button {
            Task { await toggleFollow() }
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: isFollowing ? "checkmark" : "plus")
                    .font(.system(size: 15, weight: .black))
                Text(isFollowing ? l10n.t("artist.following") : l10n.t("artist.follow"))
                    .font(.system(size: AppFontSize.md, weight: .bold))
            }
            .foregroundStyle(isFollowing ? AppColors.textPrimary : AppColors.yellowText)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isFollowing ? AppColors.card : AppColors.yellow)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(isFollowing ? AppColors.border : .clear, lineWidth: 1)
            )
            .clipShape(.rect(cornerRadius: AppRadius.md))
        }
        .buttonStyle(PressableScaleStyle())
        .disabled(followBusy)
    }

    // MARK: - Tracks

    private var tracksSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            ProfileSectionHeader(title: l10n.t("artist.tracksTitle"))
                .padding(.horizontal, AppSpacing.lg)

            if isLoading {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .fill(AppColors.card)
                            .frame(height: 64)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            } else if tracks.isEmpty {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "music.note")
                        .foregroundStyle(AppColors.textMuted)
                    Text(l10n.t("profile.noTracks"))
                        .font(.system(size: AppFontSize.sm, weight: .medium))
                        .foregroundStyle(AppColors.textMuted)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.lg)
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(tracks) { track in
                        Button {
                            MusicPlayer.shared.load(track: track)
                        } label: {
                            ArtistTrackRow(track: track)
                        }
                        .buttonStyle(PressableScaleStyle())
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
    }

    // MARK: - Data

    private func load() async {
        async let profileTask = ProfileService.shared.fetchProfile(artistId: route.artistId)
        async let tracksTask = ProfileService.shared.fetchTracks(artistId: route.artistId, liveOnly: true)

        profile = try? await profileTask
        tracks = (try? await tracksTask) ?? []
        isLoading = false

        if let userId = auth.currentUser?.id {
            isFollowing = (try? await FollowService.shared.isFollowing(artistId: route.artistId, userId: userId)) ?? false
        }

        if let s = try? await SceneStatsService.shared.fetchStats(for: route.artistId) {
            stats = s
        }
        statsLoading = false
    }

    private func toggleFollow() async {
        guard let userId = auth.currentUser?.id, !followBusy else { return }
        followBusy = true
        defer { followBusy = false }
        let wasFollowing = isFollowing
        isFollowing.toggle()
        do {
            if wasFollowing {
                try await FollowService.shared.unfollow(artistId: route.artistId, userId: userId)
            } else {
                try await FollowService.shared.follow(artistId: route.artistId, userId: userId)
            }
        } catch {
            isFollowing = wasFollowing
        }
    }

    private var initials: String {
        let name = profile?.artistName ?? route.artistName
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}
