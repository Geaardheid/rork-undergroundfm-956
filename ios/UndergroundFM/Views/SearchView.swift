//
//  SearchView.swift
//  UndergroundFM
//
//  Live zoekscherm: artiesten + tracks, debounced via PostgREST ilike.
//

import SwiftUI
import Combine

struct SearchView: View {
    @Bindable var l10n: L10n
    @Environment(\.dismiss) private var dismiss

    @State private var query: String = ""
    @State private var artists: [ArtistSearchResult] = []
    @State private var tracks: [Track] = []
    @State private var isLoading: Bool = false
    @State private var searchTask: Task<Void, Never>?
    @State private var coverTracks: [Track] = []
    @State private var newArtists: [ArtistSearchResult] = []
    @State private var recentTracks: [Track] = []
    @State private var genreCovers: [String: String] = [:]
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
            SearchDiscoverView(
                l10n: l10n,
                covers: coverTracks,
                newArtists: newArtists,
                recentTracks: recentTracks,
                genreCovers: genreCovers,
                onPlay: { track in
                    MusicPlayer.shared.load(track: track)
                    dismiss()
                }
            )
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
        if let rows = try? await SearchService.shared.mostPlayed(limit: 6) {
            coverTracks = rows
        }
        if let artists = try? await SearchService.shared.newArtists(limit: 12) {
            newArtists = artists
        }
        if let uploads = try? await SearchService.shared.recentUploads(limit: 12) {
            recentTracks = uploads
        }
        await loadGenreCovers()
    }

    /// Haal per genre de cover van de meest beluisterde track op (voor de tegels).
    private func loadGenreCovers() async {
        for section in GenreSection.all where genreCovers[section.genre] == nil {
            if let rows = try? await TracksService.shared.fetchTracks(
                genre: section.genre,
                orderBy: .trending,
                limit: 1
            ), let cover = rows.first?.thumbnailUrl {
                genreCovers[section.genre] = cover
            }
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

/// Lege staat van het zoekscherm — Spotify-stijl discover in Underground FM kleuren.
private struct SearchDiscoverView: View {
    @Bindable var l10n: L10n
    let covers: [Track]
    let newArtists: [ArtistSearchResult]
    let recentTracks: [Track]
    let genreCovers: [String: String]
    let onPlay: (Track) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.md),
        GridItem(.flexible(), spacing: AppSpacing.md)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                FloatingCoverStrip(tracks: Array(covers.prefix(3)), onPlay: onPlay)
                    .padding(.top, AppSpacing.sm)

                genresSection

                if !newArtists.isEmpty {
                    artistsSection
                }

                if !recentTracks.isEmpty {
                    uploadsSection
                }

                Color.clear.frame(height: 100)
            }
            .padding(.top, AppSpacing.sm)
        }
    }

    // MARK: Genres

    private var genresSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(emoji: "\u{26A1}", title: l10n.t("search.browseGenres"))
                .padding(.horizontal, AppSpacing.lg)

            LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                ForEach(GenreSection.all) { section in
                    NavigationLink(value: section) {
                        GenreTile(
                            emoji: section.emoji,
                            name: genreDisplayName(section.genre),
                            tint: genreTint(section.genre),
                            coverUrl: genreCovers[section.genre]
                        )
                    }
                    .buttonStyle(PressableScaleStyle())
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }

    // MARK: New artists

    private var artistsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(emoji: "\u{26A1}", title: l10n.t("search.newArtists"))
                .padding(.horizontal, AppSpacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.lg) {
                    ForEach(newArtists) { artist in
                        NavigationLink(value: ArtistRoute(artistId: artist.id, artistName: artist.artistName)) {
                            DiscoverArtistCard(artist: artist)
                        }
                        .buttonStyle(PressableScaleStyle())
                    }
                }
            }
            .contentMargins(.horizontal, AppSpacing.lg)
        }
    }

    // MARK: Recent uploads

    private var uploadsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(emoji: "\u{1F525}", title: l10n.t("search.recentUploads"))
                .padding(.horizontal, AppSpacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.lg) {
                    ForEach(recentTracks) { track in
                        Button {
                            MusicPlayer.shared.load(track: track)
                        } label: {
                            DiscoverTrackCard(track: track)
                        }
                        .buttonStyle(PressableScaleStyle())
                    }
                }
            }
            .contentMargins(.horizontal, AppSpacing.lg)
        }
    }

    private func sectionHeader(emoji: String, title: String) -> some View {
        HStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: 18, weight: .black))
            Text(title.uppercased())
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(AppColors.yellow)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func genreDisplayName(_ raw: String) -> String {
        switch raw.lowercased() {
        case "rb", "r&b": return "R&B"
        default: return raw.prefix(1).uppercased() + raw.dropFirst()
        }
    }

    /// Subtiele kleurtint per genre voor de tegel-gradient.
    private func genreTint(_ raw: String) -> Color {
        switch raw.lowercased() {
        case "rap":   return Color(hex: 0x7A1F1F) // donkerrood
        case "drill": return Color(hex: 0x1F2F7A) // donkerblauw
        case "afro":  return Color(hex: 0x1F5A2E) // donkergroen
        case "trap":  return Color(hex: 0x4A1F7A) // donkerpaars
        case "rb":    return Color(hex: 0x8A4A12) // donkeroranje
        case "house": return Color(hex: 0x12605A) // donkerteal
        default:      return AppColors.cardHover
        }
    }
}

// MARK: - Floating cover strip

/// Horizontale strook van 3 schuine covers met gele glow + crossfade van de huidige track-info.
private struct FloatingCoverStrip: View {
    let tracks: [Track]
    let onPlay: (Track) -> Void
    @State private var activeIndex: Int = 0

    private let angles: [Double] = [-8, 6, -5]

    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            HStack(spacing: -24) {
                ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                    FloatingCover(url: track.thumbnailUrl, highlighted: index == activeIndex) {
                        onPlay(track)
                    }
                    .rotationEffect(.degrees(angles[index % angles.count]))
                    .zIndex(index == activeIndex ? 10 : Double(index))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)

            if tracks.indices.contains(activeIndex) {
                let track = tracks[activeIndex]
                VStack(spacing: 3) {
                    Text(track.title)
                        .font(.system(size: AppFontSize.md, weight: .black))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                    Text(track.artistName)
                        .font(.system(size: AppFontSize.base, weight: .bold))
                        .foregroundStyle(AppColors.yellow)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AppSpacing.lg)
                .id(track.id)
                .transition(.opacity)
            }
        }
        .onReceive(timer) { _ in
            guard tracks.count > 1 else { return }
            withAnimation(.easeInOut(duration: 0.5)) {
                activeIndex = (activeIndex + 1) % tracks.count
            }
        }
    }
}

private struct FloatingCover: View {
    let url: String?
    var highlighted: Bool = false
    let onTap: () -> Void
    @State private var appeared: Bool = false
    @State private var tapScale: CGFloat = 1

    var body: some View {
        Button(action: handleTap) {
            cover
        }
        .buttonStyle(.plain)
    }

    private var cover: some View {
        Color(AppColors.card)
            .frame(width: 110, height: 110)
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
                    .stroke(AppColors.yellow.opacity(highlighted ? 0.9 : 0.5), lineWidth: highlighted ? 2 : 1.5)
            )
            .shadow(color: AppColors.yellow.opacity(highlighted ? 0.85 : 0.5), radius: highlighted ? 26 : 16)
            .scaleEffect((highlighted ? 1.06 : (appeared ? 1 : 0.7)) * tapScale)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.45, dampingFraction: 0.7), value: highlighted)
            .onAppear {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.7).delay(Double.random(in: 0...0.2))) {
                    appeared = true
                }
            }
    }

    private func handleTap() {
        withAnimation(.easeInOut(duration: 0.12)) {
            tapScale = 0.95
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                tapScale = 1
            }
        }
        onTap()
    }

    private var placeholder: some View {
        Image(systemName: "music.note")
            .font(.system(size: 26, weight: .bold))
            .foregroundStyle(AppColors.textMuted)
    }
}

// MARK: - Genre tile (Spotify-stijl rechthoek)

private struct GenreTile: View {
    let emoji: String
    let name: String
    let tint: Color
    let coverUrl: String?

    var body: some View {
        Color(AppColors.card)
            .frame(height: 96)
            .overlay {
                if let coverUrl, let u = URL(string: coverUrl) {
                    AsyncImage(url: u) { phase in
                        if case .success(let img) = phase {
                            img.resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
            .overlay(
                LinearGradient(
                    colors: [tint.opacity(0.92), tint.opacity(0.55), .black.opacity(0.65)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .topLeading) {
                Text(name)
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                    .padding(AppSpacing.md)
            }
            .overlay(alignment: .bottomTrailing) {
                Text(emoji)
                    .font(.system(size: 32))
                    .rotationEffect(.degrees(12))
                    .padding(.trailing, AppSpacing.sm)
                    .padding(.bottom, 2)
            }
            .clipShape(.rect(cornerRadius: AppRadius.lg))
    }
}

// MARK: - Discover artist card

private struct DiscoverArtistCard: View {
    let artist: ArtistSearchResult

    private var initials: String {
        let parts = artist.artistName.split(separator: " ")
        let chars = parts.prefix(2).compactMap { $0.first }
        return String(chars).uppercased()
    }

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            ProfileAvatar(initials: initials, photoUrl: artist.avatarUrl, size: 84)
            VStack(spacing: 3) {
                Text(artist.artistName)
                    .font(.system(size: AppFontSize.sm, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                if artist.isFoundingArtist {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8, weight: .black))
                        Text("Founding")
                            .font(.system(size: 9, weight: .black))
                    }
                    .foregroundStyle(AppColors.yellow)
                }
            }
        }
        .frame(width: 96)
    }
}

// MARK: - Discover track card

private struct DiscoverTrackCard: View {
    let track: Track

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            TrackThumbnail(
                url: track.thumbnailUrl,
                cornerRadius: AppRadius.md,
                isCurrent: MusicPlayer.shared.currentTrack?.id == track.id,
                isPlaying: MusicPlayer.shared.currentTrack?.id == track.id && MusicPlayer.shared.isPlaying,
                hasVideo: track.videoUrl != nil
            )
            .frame(width: 140, height: 140)

            Text(track.title)
                .font(.system(size: AppFontSize.sm, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
            Text(track.artistName)
                .font(.system(size: AppFontSize.xs, weight: .bold))
                .foregroundStyle(AppColors.yellow)
                .lineLimit(1)
        }
        .frame(width: 140)
    }
}
