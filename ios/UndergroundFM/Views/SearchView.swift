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
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                searchFocused = true
            }
        }
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
            emptyState(icon: "magnifyingglass", text: l10n.t("search.empty"))
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
            TrackThumbnail(url: track.thumbnailUrl, isCurrent: isCurrent, isPlaying: isCurrent && MusicPlayer.shared.isPlaying)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.system(size: AppFontSize.base, weight: .bold))
                    .foregroundStyle(isCurrent ? AppColors.yellow : AppColors.textPrimary)
                    .lineLimit(1)
                Text(track.artistName)
                    .font(.system(size: AppFontSize.sm, weight: .medium))
                    .foregroundStyle(AppColors.textSecond)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(.system(size: 9, weight: .black))
                Text(formatCount(track.streamCount))
                    .font(.system(size: AppFontSize.xs, weight: .semibold))
            }
            .foregroundStyle(AppColors.textMuted)
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
