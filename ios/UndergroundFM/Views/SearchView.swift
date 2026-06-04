//
//  SearchView.swift
//  UndergroundFM
//
//  Live zoekscherm: artiesten + tracks, debounced via PostgREST ilike.
//

import SwiftUI

struct SearchView: View {
    @Bindable var l10n: L10n
    @Environment(\.dismiss) private var dismiss

    @State private var query: String = ""
    @State private var artists: [ArtistSearchResult] = []
    @State private var tracks: [Track] = []
    @State private var isLoading: Bool = false
    @State private var searchTask: Task<Void, Never>?
    @State private var coverTracks: [Track] = []
    @FocusState private var searchFocused: Bool

    private var hasQuery: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasResults: Bool {
        !artists.isEmpty || !tracks.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                    resultsArea
                }
            }
            .navigationDestination(for: ArtistRoute.self) { route in
                ArtistProfileView(route: route, l10n: l10n)
            }
            .navigationDestination(for: GenreSection.self) { section in
                GenreDetailView(section: section, l10n: l10n)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                searchFocused = true
            }
        }
        .task { await loadCovers() }
        .onChange(of: query) { _, newValue in
            scheduleSearch(newValue)
        }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.yellow)

                TextField(
                    "",
                    text: $query,
                    prompt: Text(l10n.t("search.placeholder"))
                        .foregroundColor(AppColors.textMuted)
                )
                .focused($searchFocused)
                .foregroundStyle(AppColors.textPrimary)
                .tint(AppColors.yellow)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)

                if hasQuery {
                    Button {
                        query = ""
                        artists = []
                        tracks = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppColors.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 12)
            .background(AppColors.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(AppColors.yellow.opacity(0.4), lineWidth: 1)
            )
            .clipShape(.rect(cornerRadius: AppRadius.md))

            Button {
                dismiss()
            } label: {
                Text(l10n.t("common.cancel"))
                    .font(.system(size: AppFontSize.base, weight: .bold))
                    .foregroundStyle(AppColors.yellow)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.sm)
    }

    // MARK: - Results

    @ViewBuilder
    private var resultsArea: some View {
        if !hasQuery {
            SearchDiscoverView(l10n: l10n, covers: coverTracks)
        } else if isLoading && !hasResults {
            ProgressView()
                .tint(AppColors.yellow)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !hasResults {
            emptyState(icon: "questionmark.circle", text: l10n.t("search.noResults"))
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: AppSpacing.xl) {
                    if !artists.isEmpty {
                        artistsSection
                    }
                    if !tracks.isEmpty {
                        tracksSection
                    }
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
            }
        }
    }

    private var artistsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            ProfileSectionHeader(title: l10n.t("search.artists"))
            ForEach(artists) { artist in
                NavigationLink(value: ArtistRoute(artistId: artist.id, artistName: artist.artistName)) {
                    ArtistResultRow(artist: artist)
                }
                .buttonStyle(PressableScaleStyle())
            }
        }
    }

    private var tracksSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            ProfileSectionHeader(title: l10n.t("search.tracks"))
            ForEach(tracks) { track in
                Button {
                    MusicPlayer.shared.load(track: track)
                } label: {
                    TrackResultRow(
                        track: track,
                        isCurrent: MusicPlayer.shared.currentTrack?.id == track.id
                    )
                }
                .buttonStyle(PressableScaleStyle())
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
        .padding(.horizontal, AppSpacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadCovers() async {
        guard coverTracks.isEmpty else { return }
        if let rows = try? await SearchService.shared.mostPlayed(limit: 5) {
            coverTracks = rows
        }
    }

    // MARK: - Debounced search

    private func scheduleSearch(_ value: String) {
        searchTask?.cancel()
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            artists = []
            tracks = []
            isLoading = false
            return
        }
        isLoading = true
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            if Task.isCancelled { return }
            do {
                let result = try await SearchService.shared.search(query: trimmed)
                if Task.isCancelled { return }
                artists = result.artists
                tracks = result.tracks
            } catch {
                if Task.isCancelled { return }
                artists = []
                tracks = []
            }
            isLoading = false
        }
    }
}

// MARK: - Artist result row

private struct ArtistResultRow: View {
    let artist: ArtistSearchResult

    private var initials: String {
        let parts = artist.artistName.split(separator: " ")
        let chars = parts.prefix(2).compactMap { $0.first }
        return String(chars).uppercased()
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ProfileAvatar(initials: initials, photoUrl: artist.avatarUrl, size: 52)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(artist.artistName)
                        .font(.system(size: AppFontSize.base, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                    if artist.isFoundingArtist {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(AppColors.yellow)
                    }
                }
                if !artist.genreTags.isEmpty {
                    Text(artist.genreTags.map { displayName($0) }.joined(separator: " · "))
                        .font(.system(size: AppFontSize.sm, weight: .medium))
                        .foregroundStyle(AppColors.textSecond)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(AppSpacing.sm)
        .background(AppColors.card)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .clipShape(.rect(cornerRadius: AppRadius.md))
    }

    private func displayName(_ raw: String) -> String {
        switch raw.lowercased() {
        case "rb", "r&b": return "R&B"
        default: return raw.prefix(1).uppercased() + raw.dropFirst()
        }
    }
}

// MARK: - Track result row

private struct TrackResultRow: View {
    let track: Track
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            TrackThumbnail(
                url: track.thumbnailUrl,
                cornerRadius: AppRadius.sm,
                isCurrent: isCurrent,
                isPlaying: isCurrent && MusicPlayer.shared.isPlaying,
                hasVideo: track.videoUrl != nil
            )
            .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.system(size: AppFontSize.base, weight: .bold))
                    .foregroundStyle(isCurrent ? AppColors.yellow : AppColors.textPrimary)
                    .lineLimit(1)
                Text(track.artistName)
                    .font(.system(size: AppFontSize.sm, weight: .bold))
                    .foregroundStyle(AppColors.yellow)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(.system(size: 9, weight: .black))
                Text(formatCount(track.streamCount))
                    .font(.system(size: AppFontSize.xs, weight: .bold))
            }
            .foregroundStyle(AppColors.textSecond)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(AppColors.bg)
            .clipShape(Capsule())
        }
        .padding(AppSpacing.sm)
        .background(AppColors.card)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(isCurrent ? AppColors.yellow : AppColors.border, lineWidth: 1)
        )
        .clipShape(.rect(cornerRadius: AppRadius.md))
    }
}

// MARK: - Discover (empty state)

/// Lege staat van het zoekscherm: zwevende covers + genre-tegels.
private struct SearchDiscoverView: View {
    @Bindable var l10n: L10n
    let covers: [Track]

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.md),
        GridItem(.flexible(), spacing: AppSpacing.md)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppSpacing.xl) {
                FloatingCoverWall(tracks: covers)
                    .frame(height: 260)
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text(l10n.t("search.browseGenres"))
                        .font(.system(size: AppFontSize.md, weight: .black))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                        ForEach(GenreSection.all) { section in
                            NavigationLink(value: section) {
                                GenreTile(emoji: section.emoji, name: genreDisplayName(section.genre))
                            }
                            .buttonStyle(PressableScaleStyle())
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)

                Color.clear.frame(height: 100)
            }
            .padding(.top, AppSpacing.md)
        }
    }

    private func genreDisplayName(_ raw: String) -> String {
        switch raw.lowercased() {
        case "rb", "r&b": return "R&B"
        default: return raw.prefix(1).uppercased() + raw.dropFirst()
        }
    }
}

/// Zwevende, geroteerde covers met gele glow — scattered over de bovenste helft.
private struct FloatingCoverWall: View {
    let tracks: [Track]

    /// Vaste posities (relatief), rotaties en z-volgorde voor maximaal 5 covers.
    private let layout: [(x: CGFloat, y: CGFloat, angle: Double)] = [
        (0.50, 0.34, -6),
        (0.20, 0.22,  7),
        (0.80, 0.26, -8),
        (0.32, 0.66,  5),
        (0.70, 0.70, -4)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(tracks.prefix(5).enumerated()), id: \.element.id) { index, track in
                    let spot = layout[index % layout.count]
                    FloatingCover(url: track.thumbnailUrl)
                        .rotationEffect(.degrees(spot.angle))
                        .position(x: geo.size.width * spot.x, y: geo.size.height * spot.y)
                        .zIndex(Double(index))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct FloatingCover: View {
    let url: String?
    @State private var appeared: Bool = false

    var body: some View {
        Color(AppColors.card)
            .frame(width: 120, height: 120)
            .overlay {
                if let urlStr = url, let u = URL(string: urlStr) {
                    AsyncImage(url: u) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        default:
                            placeholder
                        }
                    }
                } else {
                    placeholder
                }
            }
            .clipShape(.rect(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(AppColors.yellow.opacity(0.5), lineWidth: 1.5)
            )
            .shadow(color: AppColors.yellow.opacity(0.6), radius: 20)
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.7).delay(Double.random(in: 0...0.25))) {
                    appeared = true
                }
            }
    }

    private var placeholder: some View {
        Image(systemName: "music.note")
            .font(.system(size: 28, weight: .bold))
            .foregroundStyle(AppColors.textMuted)
    }
}

private struct GenreTile: View {
    let emoji: String
    let name: String

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Text(emoji)
                .font(.system(size: 34))
            Text(name)
                .font(.system(size: AppFontSize.md, weight: .black))
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1.4, contentMode: .fit)
        .background(AppColors.headerBg)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .stroke(AppColors.yellow.opacity(0.6), lineWidth: 1.5)
        )
        .clipShape(.rect(cornerRadius: AppRadius.lg))
    }
}
