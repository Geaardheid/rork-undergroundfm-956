//
//  LibraryView.swift
//  UndergroundFM
//
//  Bibliotheek-tab — visuele hybride layout: hero, snelkoppelingen-grid en recent.
//

import SwiftUI

struct LibraryView: View {
    @Bindable var l10n: L10n
    @Environment(AuthStore.self) private var auth

    @State private var store = LibraryStore()
    @State private var path = NavigationPath()
    @State private var showCreateSheet: Bool = false

    /// Snelkoppelingsbestemmingen vanuit het grid.
    enum LibraryDestination: Hashable {
        case liked
        case recentlyPlayed
        case playlists
        case artists
    }

    private let gridColumns = [
        GridItem(.flexible(), spacing: AppSpacing.md),
        GridItem(.flexible(), spacing: AppSpacing.md),
    ]

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AppColors.bg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppSpacing.xl) {
                        LibraryHero(
                            coverUrls: likedCovers,
                            title: l10n.t("tab.library"),
                            onCreate: { showCreateSheet = true }
                        )

                        shortcutGrid
                            .padding(.horizontal, AppSpacing.lg)

                        if !store.likedTracks.isEmpty {
                            recentStrip
                        }

                        Color.clear.frame(height: 140)
                    }
                }
                .refreshable { await reload() }
            }
            .navigationDestination(for: LibraryDestination.self) { destination in
                switch destination {
                case .liked:
                    LikedSongsView(store: store, l10n: l10n)
                case .recentlyPlayed:
                    RecentlyPlayedView(store: store, l10n: l10n)
                case .playlists:
                    PlaylistsListView(store: store, l10n: l10n)
                case .artists:
                    FollowedArtistsView(store: store, l10n: l10n)
                }
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

    // MARK: - Shortcut grid

    private var shortcutGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: AppSpacing.md) {
            Button {
                path.append(LibraryDestination.liked)
            } label: {
                LibraryShortcutCard(
                    title: l10n.t("library.shortcutLiked"),
                    icon: "heart.fill",
                    covers: firstCover(store.likedTracks)
                )
            }
            .buttonStyle(PressableScaleStyle())

            Button {
                path.append(LibraryDestination.recentlyPlayed)
            } label: {
                LibraryShortcutCard(
                    title: l10n.t("library.shortcutRecent"),
                    icon: "clock.fill",
                    covers: firstCover(store.likedTracks)
                )
            }
            .buttonStyle(PressableScaleStyle())

            Button {
                path.append(LibraryDestination.playlists)
            } label: {
                LibraryShortcutCard(
                    title: l10n.t("library.playlists"),
                    icon: "music.note.list",
                    covers: playlistCovers
                )
            }
            .buttonStyle(PressableScaleStyle())

            Button {
                path.append(LibraryDestination.artists)
            } label: {
                LibraryShortcutCard(
                    title: l10n.t("library.artists"),
                    icon: "person.2.fill",
                    covers: artistAvatars
                )
            }
            .buttonStyle(PressableScaleStyle())
        }
    }

    // MARK: - Recent strip

    private var recentStrip: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(l10n.t("library.recentTitle").uppercased())
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(AppColors.yellow)
                .padding(.horizontal, AppSpacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.lg) {
                    ForEach(Array(store.likedTracks.enumerated()), id: \.element.id) { index, track in
                        Button {
                            MusicPlayer.shared.setQueue(store.likedTracks, startingAt: index)
                        } label: {
                            RecentTrackCard(track: track)
                        }
                        .buttonStyle(PressableScaleStyle())
                    }
                }
            }
            .contentMargins(.horizontal, AppSpacing.lg)
        }
    }

    // MARK: - Cover helpers

    /// Tot 5 covers voor de hero-collage.
    private var likedCovers: [String] {
        Array(store.likedTracks.compactMap { $0.thumbnailUrl }.prefix(5))
    }

    private func firstCover(_ tracks: [Track]) -> [String] {
        guard let cover = tracks.first?.thumbnailUrl else { return [] }
        return [cover]
    }

    /// Eerste cover van maximaal 4 playlists voor de tegel-collage.
    private var playlistCovers: [String] {
        Array(store.playlists.compactMap { store.covers(for: $0.id).first }.prefix(4))
    }

    private var artistAvatars: [String] {
        Array(store.followedArtists.compactMap { $0.avatarUrl }.prefix(4))
    }
}
