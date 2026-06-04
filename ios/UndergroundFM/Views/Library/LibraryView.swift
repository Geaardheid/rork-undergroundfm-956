//
//  LibraryView.swift
//  UndergroundFM
//
//  Bibliotheek-tab — gelikete tracks, gevolgde artiesten en playlists.
//

import SwiftUI

struct LibraryView: View {
    @Bindable var l10n: L10n
    @Environment(AuthStore.self) private var auth

    @State private var store = LibraryStore()
    @State private var filter: LibraryFilter = .tracks
    @State private var path = NavigationPath()
    @State private var showCreateSheet: Bool = false

    enum LibraryFilter: String, CaseIterable, Identifiable {
        case tracks, artists, playlists
        var id: String { rawValue }
        var labelKey: String {
            switch self {
            case .tracks:    return "library.tracks"
            case .artists:   return "library.artists"
            case .playlists: return "library.playlists"
            }
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            FloatingHeaderScreen(header: { header }, onRefresh: { await reload() }) {
                LazyVStack(alignment: .leading, spacing: AppSpacing.lg) {
                    filterChips
                    if filter == .tracks { sortMenu }

                    Group {
                        switch filter {
                        case .tracks:    tracksSection
                        case .artists:   artistsSection
                        case .playlists: playlistsSection
                        }
                    }
                    .transition(.opacity)

                    Color.clear.frame(height: 140)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
            }
            .navigationDestination(for: ArtistRoute.self) { route in
                ArtistProfileView(route: route, l10n: l10n)
            }
            .navigationDestination(for: Playlist.self) { playlist in
                PlaylistDetailView(playlist: playlist, l10n: l10n)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task {
            if store.likedTracks.isEmpty && store.playlists.isEmpty && store.followedArtists.isEmpty {
                await reload()
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreatePlaylistSheet(l10n: l10n) {
                await reload()
            }
            .presentationDetents([.medium])
            .presentationBackground(AppColors.bg)
        }
    }

    private func reload() async {
        guard let userId = auth.currentUser?.id else { return }
        await store.loadAll(userId: userId)
    }

    // MARK: - Header

    private var header: some View {
        FloatingHeaderTitle(title: l10n.t("tab.library"))
    }

    // MARK: - Chips + sort

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(LibraryFilter.allCases) { f in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            filter = f
                        }
                    } label: {
                        Text(l10n.t(f.labelKey))
                            .font(.system(size: AppFontSize.sm, weight: .bold))
                            .foregroundStyle(filter == f ? AppColors.yellowText : AppColors.textPrimary)
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.vertical, 9)
                            .background(filter == f ? AppColors.yellow : AppColors.card)
                            .overlay(
                                Capsule().stroke(filter == f ? .clear : AppColors.border, lineWidth: 1)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PressableScaleStyle())
                }
            }
        }
        .scrollClipDisabled()
    }

    private var sortMenu: some View {
        Menu {
            ForEach(LibraryStore.TrackSort.allCases) { option in
                Button {
                    store.sort = option
                } label: {
                    HStack {
                        Text(l10n.t(option.labelKey))
                        if store.sort == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 12, weight: .bold))
                Text(l10n.t(store.sort.labelKey))
                    .font(.system(size: AppFontSize.sm, weight: .bold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(AppColors.yellow)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 8)
            .background(AppColors.card)
            .overlay(Capsule().stroke(AppColors.yellow.opacity(0.4), lineWidth: 1))
            .clipShape(Capsule())
        }
    }

    // MARK: - Tracks

    @ViewBuilder
    private var tracksSection: some View {
        if store.isLoading && store.likedTracks.isEmpty {
            loadingRows
        } else if store.likedTracks.isEmpty {
            emptyState(icon: "heart", text: l10n.t("library.noTracks"))
        } else {
            VStack(spacing: AppSpacing.sm) {
                ForEach(store.likedTracks) { track in
                    SwipeToDeleteRow(
                        deleteLabel: l10n.t("library.unlike"),
                        onDelete: {
                            if let userId = auth.currentUser?.id {
                                await store.unlike(track: track, userId: userId)
                            }
                        }
                    ) {
                        Button {
                            MusicPlayer.shared.load(track: track)
                        } label: {
                            LibraryTrackRow(
                                track: track,
                                isCurrent: MusicPlayer.shared.currentTrack?.id == track.id,
                                playlists: store.playlists,
                                onAddToPlaylist: { playlist in
                                    Task { await addTrack(track, to: playlist) }
                                }
                            )
                        }
                        .buttonStyle(PressableScaleStyle())
                    }
                }
            }
        }
    }

    private func addTrack(_ track: Track, to playlist: Playlist) async {
        try? await PlaylistService.shared.addTrack(
            playlistId: playlist.id,
            trackId: track.id,
            currentCount: playlist.trackCount
        )
        await reload()
    }

    // MARK: - Artists

    @ViewBuilder
    private var artistsSection: some View {
        if store.isLoading && store.followedArtists.isEmpty {
            loadingRows
        } else if store.followedArtists.isEmpty {
            emptyState(icon: "person.2", text: l10n.t("library.noArtists"))
        } else {
            VStack(spacing: AppSpacing.sm) {
                ForEach(store.followedArtists) { artist in
                    Button {
                        path.append(ArtistRoute(artistId: artist.id, artistName: artist.artistName))
                    } label: {
                        LibraryArtistRow(artist: artist, l10n: l10n)
                    }
                    .buttonStyle(PressableScaleStyle())
                }
            }
        }
    }

    // MARK: - Playlists

    @ViewBuilder
    private var playlistsSection: some View {
        VStack(spacing: AppSpacing.md) {
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

            if store.playlists.isEmpty && !store.isLoading {
                emptyState(icon: "music.note.list", text: l10n.t("library.noPlaylists"))
            } else {
                ForEach(store.playlists) { playlist in
                    Button {
                        path.append(playlist)
                    } label: {
                        PlaylistRow(
                            playlist: playlist,
                            covers: store.covers(for: playlist.id),
                            l10n: l10n
                        )
                    }
                    .buttonStyle(PressableScaleStyle())
                }
            }
        }
    }

    // MARK: - Shared

    private var loadingRows: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(0..<5, id: \.self) { _ in
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(AppColors.card)
                    .frame(height: 64)
            }
        }
    }

    private func emptyState(icon: String, text: String) -> some View {
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
