//
//  GenreDetailView.swift
//  UndergroundFM
//
//  Volledige lijst van alle tracks binnen één genre-sectie ("Alles zien").
//

import SwiftUI

struct GenreDetailView: View {
    let section: GenreSection
    @Bindable var l10n: L10n

    @State private var tracks: [Track] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

    private let service = TracksService.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            content
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, 120)
        }
        .background(AppColors.bg.ignoresSafeArea())
        .navigationTitle(l10n.t(section.titleKey))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .tint(AppColors.yellow)
        .task {
            if tracks.isEmpty { await load() }
        }
        .refreshable { await load() }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && tracks.isEmpty {
            VStack(spacing: AppSpacing.sm) {
                ForEach(0..<8, id: \.self) { _ in
                    GenreTrackRowSkeleton()
                }
            }
        } else if let errorMessage, tracks.isEmpty {
            errorState(message: errorMessage)
        } else if tracks.isEmpty {
            emptyState
        } else {
            LazyVStack(spacing: AppSpacing.sm) {
                ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                    Button {
                        MusicPlayer.shared.setQueue(tracks, startingAt: index)
                    } label: {
                        GenreTrackRow(
                            track: track,
                            isCurrent: MusicPlayer.shared.currentTrack?.id == track.id
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "music.note")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
            Text(l10n.t("feed.emptyGenre"))
                .font(.system(size: AppFontSize.base, weight: .medium))
                .foregroundStyle(AppColors.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(AppColors.warning)
            Text(l10n.t("feed.errorTitle"))
                .font(.system(size: AppFontSize.base, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
            Text(message)
                .font(.system(size: AppFontSize.sm))
                .foregroundStyle(AppColors.textMuted)
                .multilineTextAlignment(.center)
            Button {
                Task { await load() }
            } label: {
                Text(l10n.t("feed.retry"))
                    .font(.system(size: AppFontSize.sm, weight: .bold))
                    .foregroundStyle(AppColors.yellow)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private func load() async {
        if tracks.isEmpty { isLoading = true }
        errorMessage = nil
        do {
            let result = try await service.fetchTracks(
                genre: section.genre,
                orderBy: section.orderBy,
                limit: 100
            )
            tracks = result
        } catch {
            // Bewaar bestaande data; toon alleen een fout als er niets te tonen valt.
            if tracks.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }
}

// MARK: - Row

struct GenreTrackRow: View {
    let track: Track
    var isCurrent: Bool = false

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            TrackThumbnail(
                url: track.thumbnailUrl,
                cornerRadius: AppRadius.sm,
                isCurrent: isCurrent,
                isPlaying: isCurrent && MusicPlayer.shared.isPlaying
            )
            .frame(width: 60)

            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.system(size: AppFontSize.base, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                Text(track.artistName)
                    .font(.system(size: AppFontSize.sm, weight: .medium))
                    .foregroundStyle(AppColors.textSecond)
                    .lineLimit(1)
                HStack(spacing: AppSpacing.md) {
                    Label(formatCount(track.streamCount), systemImage: "play.fill")
                    if let d = track.duration, d > 0 {
                        Label(formatDuration(d), systemImage: "clock")
                    }
                }
                .font(.system(size: AppFontSize.xs, weight: .semibold))
                .foregroundStyle(AppColors.textMuted)
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.sm)
        .frame(maxWidth: .infinity)
        .background(isCurrent ? AppColors.yellow.opacity(0.08) : AppColors.card)
        .overlay(alignment: .leading) {
            if isCurrent {
                AppColors.yellow
                    .frame(width: 4)
                    .clipShape(.rect(cornerRadius: 2))
            }
        }
        .clipShape(.rect(cornerRadius: AppRadius.md))
        .contentShape(Rectangle())
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

struct GenreTrackRowSkeleton: View {
    @State private var pulse: Bool = false

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .fill(AppColors.card)
                .frame(width: 60, height: 60)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4).fill(AppColors.card).frame(width: 160, height: 12)
                RoundedRectangle(cornerRadius: 4).fill(AppColors.card).frame(width: 110, height: 10)
                RoundedRectangle(cornerRadius: 4).fill(AppColors.card).frame(width: 80, height: 9)
            }
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.sm)
        .opacity(pulse ? 0.6 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
