//
//  LibrarySubViews.swift
//  UndergroundFM
//
//  Detailschermen die vanuit het Bibliotheek-grid worden geopend:
//  gelikete nummers, laatst geluisterd, playlists en gevolgde artiesten.
//

import SwiftUI

// MARK: - Liked songs (auto-playlist)

/// "Gelikte nummers" — alle gelikete tracks als playlist met "Alles afspelen".
struct LikedSongsView: View {
    let store: LibraryStore
    @Bindable var l10n: L10n
    @Environment(AuthStore.self) private var auth

    var body: some View {
        ZStack {
            AppColors.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppSpacing.lg) {
                    header
                    playAllButton
                    tracksList
                    Color.clear.frame(height: 140)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)
            }
        }
        .navigationTitle(l10n.t("library.likedPlaylist"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.bg, for: .navigationBar)
    }

    private var header: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppColors.yellow, AppColors.yellow.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                Image(systemName: "heart.fill")
                    .font(.system(size: 64, weight: .black))
                    .foregroundStyle(AppColors.yellowText)
            }
            .shadow(color: AppColors.yellow.opacity(0.4), radius: 16)

            Text(l10n.t("library.likedPlaylist"))
                .font(.system(size: AppFontSize.xxl, weight: .black))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(l10n.t("library.trackCount").replacingOccurrences(of: "%@", with: "\(store.likedTracks.count)"))
                .font(.system(size: AppFontSize.sm, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
        }
    }

    private var playAllButton: some View {
        Button {
            MusicPlayer.shared.setQueue(store.likedTracks, startingAt: 0)
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .black))
                Text(l10n.t("library.playAll"))
                    .font(.system(size: AppFontSize.md, weight: .bold))
            }
            .foregroundStyle(AppColors.yellowText)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppColors.yellow)
            .clipShape(.rect(cornerRadius: AppRadius.md))
        }
        .buttonStyle(PressableScaleStyle())
        .disabled(store.likedTracks.isEmpty)
        .opacity(store.likedTracks.isEmpty ? 0.5 : 1)
    }

    @ViewBuilder
    private var tracksList: some View {
        if store.likedTracks.isEmpty {
            EmptyLibrarySection(icon: "heart", text: l10n.t("library.noTracks"))
        } else {
            VStack(spacing: AppSpacing.sm) {
                ForEach(Array(store.likedTracks.enumerated()), id: \.element.id) { index, track in
                    SwipeToDeleteRow(
                        deleteLabel: l10n.t("library.unlike"),
                        onDelete: {
                            if let userId = auth.currentUser?.id {
                                await store.unlike(track: track, userId: userId)
                            }
                        }
                    ) {
                        Button {
                            MusicPlayer.shared.setQueue(store.likedTracks, startingAt: index)
                        } label: {
                            LibraryTrackRow(
                                track: track,
                                isCurrent: MusicPlayer.shared.currentTrack?.id == track.id,
                                playlists: store.playlists,
                                onAddToPlaylist: { playlist in
                                    Task {
                                        try? await PlaylistService.shared.addTrack(
                                            playlistId: playlist.id,
                                            trackId: track.id,
                                            currentCount: playlist.trackCount
                                        )
                                    }
                                }
                            )
                        }
                        .buttonStyle(PressableScaleStyle())
                    }
                }
            }
        }
    }
}

// MARK: - Recently played

/// Laatst geluisterde tracks (gelikete tracks op afspeel-volgorde).
struct RecentlyPlayedView: View {
    let store: LibraryStore
    @Bindable var l10n: L10n

    var body: some View {
        ZStack {
            AppColors.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppSpacing.sm) {
                    if store.likedTracks.isEmpty {
                        EmptyLibrarySection(icon: "clock", text: l10n.t("library.noTracks"))
                    } else {
                        ForEach(Array(store.likedTracks.enumerated()), id: \.element.id) { index, track in
                            Button {
                                MusicPlayer.shared.setQueue(store.likedTracks, startingAt: index)
                            } label: {
                                LibraryTrackRow(
                                    track: track,
                                    isCurrent: MusicPlayer.shared.currentTrack?.id == track.id
                                )
                            }
                            .buttonStyle(PressableScaleStyle())
                        }
                    }
                    Color.clear.frame(height: 140)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)
            }
        }
        .navigationTitle(l10n.t("library.shortcutRecent"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.bg, for: .navigationBar)
    }
}

// MARK: - Playlists list

struct PlaylistsListView: View {
    let store: LibraryStore
    @Bindable var l10n: L10n
    @Environment(AuthStore.self) private var auth

    @State private var showCreateSheet: Bool = false

    var body: some View {
        ZStack {
            AppColors.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppSpacing.md) {
                    createButton

                    if store.playlists.isEmpty && !store.isLoading {
                        EmptyLibrarySection(icon: "music.note.list", text: l10n.t("library.noPlaylists"))
                    } else {
                        ForEach(store.playlists) { playlist in
                            NavigationLink(value: playlist) {
                                PlaylistRow(
                                    playlist: playlist,
                                    covers: store.covers(for: playlist.id),
                                    l10n: l10n
                                )
                            }
                            .buttonStyle(PressableScaleStyle())
                        }
                    }
                    Color.clear.frame(height: 140)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)
            }
        }
        .navigationTitle(l10n.t("library.playlists"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.bg, for: .navigationBar)
        .sheet(isPresented: $showCreateSheet) {
            CreatePlaylistSheet(l10n: l10n) {
                if let userId = auth.currentUser?.id {
                    await store.reloadPlaylists(userId: userId)
                }
            }
            .presentationDetents([.medium])
            .presentationBackground(AppColors.bg)
        }
    }

    private var createButton: some View {
        Button {
            showCreateSheet = true
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                Text(l10n.t("library.newPlaylist"))
                    .font(.system(size: AppFontSize.md, weight: .bold))
            }
            .foregroundStyle(AppColors.yellowText)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppColors.yellow)
            .clipShape(.rect(cornerRadius: AppRadius.md))
        }
        .buttonStyle(PressableScaleStyle())
    }
}

// MARK: - Followed artists list

struct FollowedArtistsView: View {
    let store: LibraryStore
    @Bindable var l10n: L10n

    var body: some View {
        ZStack {
            AppColors.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppSpacing.sm) {
                    if store.followedArtists.isEmpty {
                        EmptyLibrarySection(icon: "person.2", text: l10n.t("library.noArtists"))
                    } else {
                        ForEach(store.followedArtists) { artist in
                            NavigationLink(value: ArtistRoute(artistId: artist.id, artistName: artist.artistName)) {
                                LibraryArtistRow(artist: artist, l10n: l10n)
                            }
                            .buttonStyle(PressableScaleStyle())
                        }
                    }
                    Color.clear.frame(height: 140)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)
            }
        }
        .navigationTitle(l10n.t("library.artists"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.bg, for: .navigationBar)
    }
}

// MARK: - Shared empty state

struct EmptyLibrarySection: View {
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
            Text(text)
                .font(.system(size: AppFontSize.base, weight: .semibold))
                .foregroundStyle(AppColors.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxxl)
    }
}
