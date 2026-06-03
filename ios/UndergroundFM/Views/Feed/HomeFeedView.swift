//
//  HomeFeedView.swift
//  UndergroundFM
//

import SwiftUI

struct HomeFeedView: View {
    @Bindable var l10n: L10n
    @State private var feed = FeedStore()
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationDestination(for: ArtistRoute.self) { route in
                    ArtistProfileView(route: route, l10n: l10n)
                }
                .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var content: some View {
        ZStack(alignment: .top) {
            AppColors.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: AppSpacing.xxl, pinnedViews: []) {
                    // Spacer voor floating header
                    Color.clear.frame(height: 64)

                    FeaturedBanner(
                        track: feed.featured,
                        isLoading: feed.isFeaturedLoading,
                        l10n: l10n,
                        onTap: {
                            if let track = feed.featured {
                                MusicPlayer.shared.load(track: track)
                            }
                        }
                    )

                    ForEach(GenreSection.all) { section in
                        GenreRow(
                            section: section,
                            state: feed.state(for: section.id),
                            l10n: l10n,
                            onSelectTrack: { track in
                                MusicPlayer.shared.load(track: track)
                            },
                            onSelectArtist: { track in
                                path.append(ArtistRoute(artistId: track.artistId, artistName: track.artistName))
                            },
                            onRetry: { Task { await feed.load(section: section) } }
                        )
                    }

                    Color.clear.frame(height: 120)
                }
                .padding(.top, AppSpacing.sm)
            }
            .refreshable {
                await feed.loadAll()
            }

            header
        }
        .task {
            if feed.featured == nil {
                await feed.loadAll()
            }
        }
    }

    // MARK: - Floating header (liquid glass on iOS 26)

    private var header: some View {
        HStack(alignment: .center) {
            LogoView(style: .wordmark, size: 64)
            Spacer()
            HStack(spacing: AppSpacing.md) {
                headerIcon("magnifyingglass")
                headerIcon("bell")
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
        .background(headerBackground)
    }

    @ViewBuilder
    private var headerBackground: some View {
        if #available(iOS 26.0, *) {
            Rectangle()
                .fill(.clear)
                .glassEffect(.regular, in: Rectangle())
                .overlay(Rectangle().fill(AppColors.bg.opacity(0.35)))
        } else {
            Rectangle()
                .fill(AppColors.bg.opacity(0.85))
                .background(.ultraThinMaterial)
        }
    }

    private func headerIcon(_ name: String) -> some View {
        Button(action: {}) {
            ZStack {
                Circle()
                    .fill(AppColors.card.opacity(0.6))
                    .frame(width: 38, height: 38)
                    .overlay(Circle().stroke(AppColors.border, lineWidth: 1))
                Image(systemName: name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .buttonStyle(.plain)
    }
}
