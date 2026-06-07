//
//  HomeFeedView.swift
//  UndergroundFM
//

import SwiftUI

struct HomeFeedView: View {
    @Bindable var l10n: L10n
    @State private var feed = FeedStore()
    @State private var path = NavigationPath()
    @State private var showSearch: Bool = false

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationDestination(for: ArtistRoute.self) { route in
                    ArtistProfileView(route: route, l10n: l10n)
                }
                .navigationDestination(for: GenreSection.self) { section in
                    GenreDetailView(section: section, l10n: l10n)
                }
                .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var content: some View {
        FloatingHeaderScreen(header: { header }, onRefresh: { await feed.loadAll() }) {
            LazyVStack(alignment: .leading, spacing: AppSpacing.xxl) {
                if let track = feed.featured {
                    FeaturedBanner(
                        track: track,
                        isLoading: false,
                        l10n: l10n,
                        isCurrent: feed.featured?.id == MusicPlayer.shared.currentTrack?.id,
                        isPlaying: MusicPlayer.shared.isPlaying,
                        onTap: {
                            if MusicPlayer.shared.currentTrack?.id == track.id {
                                MusicPlayer.shared.togglePlayPause()
                            } else {
                                MusicPlayer.shared.setQueue(featuredQueue(startingWith: track), startingAt: 0)
                            }
                        }
                    )
                } else if feed.isFeaturedLoading {
                    FeaturedBanner(
                        track: nil,
                        isLoading: true,
                        l10n: l10n
                    )
                }

                ForEach(GenreSection.all) { section in
                    GenreRow(
                        section: section,
                        state: feed.state(for: section.id),
                        l10n: l10n,
                        onSelectTrack: { track in
                            // De volledige sectie wordt de wachtrij; speel vanaf de getikte track.
                            if case .loaded(let tracks) = feed.state(for: section.id),
                               let index = tracks.firstIndex(where: { $0.id == track.id }) {
                                MusicPlayer.shared.setQueue(tracks, startingAt: index)
                            } else {
                                MusicPlayer.shared.load(track: track)
                            }
                        },
                        onSelectArtist: { track in
                            path.append(ArtistRoute(artistId: track.artistId, artistName: track.artistName))
                        },
                        onRetry: { Task { await feed.load(section: section) } },
                        onSeeAll: { path.append(section) }
                    )
                }

                Color.clear.frame(height: 120)
            }
            .padding(.top, AppSpacing.sm)
        }
        .task {
            if feed.featured == nil {
                await feed.loadAll()
            }
        }
        .fullScreenCover(isPresented: $showSearch) {
            SearchView(l10n: l10n)
        }
    }

    /// Bouwt de wachtrij voor de featured banner: de featured track eerst,
    /// gevolgd door alle geladen sectie-tracks, ontdubbeld op track.id.
    private func featuredQueue(startingWith track: Track) -> [Track] {
        var seen = Set<String>()
        var queue: [Track] = []
        if seen.insert(track.id).inserted {
            queue.append(track)
        }
        for section in GenreSection.all {
            if case .loaded(let tracks) = feed.state(for: section.id) {
                for t in tracks where seen.insert(t.id).inserted {
                    queue.append(t)
                }
            }
        }
        return queue
    }

    // MARK: - Floating transparante header (logo + iconen)

    private var header: some View {
        HStack(alignment: .center) {
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 32)
                .accessibilityLabel("UndergroundFM")
            Spacer()
            HStack(spacing: AppSpacing.md) {
                headerIcon("magnifyingglass") { showSearch = true }
            }
        }
    }

    private func headerIcon(_ name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(AppColors.card.opacity(0.6))
                    .frame(width: 38, height: 38)
                    .overlay(Circle().stroke(AppColors.yellow.opacity(0.4), lineWidth: 1))
                Image(systemName: name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.yellow)
            }
        }
        .buttonStyle(.plain)
    }
}
