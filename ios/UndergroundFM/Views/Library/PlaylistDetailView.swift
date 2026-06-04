//
//  PlaylistDetailView.swift
//  UndergroundFM
//
//  Detailpagina van een playlist — alle tracks + "Alles afspelen".
//

import SwiftUI

struct PlaylistDetailView: View {
    let playlist: Playlist
    @Bindable var l10n: L10n

    @State private var tracks: [Track] = []
    @State private var covers: [String] = []
    @State private var isLoading: Bool = true

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
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.bg, for: .navigationBar)
        .task { await load() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: AppSpacing.md) {
            PlaylistCover(name: playlist.name, covers: covers, size: 160)

            Text(playlist.name)
                .font(.system(size: AppFontSize.xxl, weight: .black))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            if let desc = playlist.description, !desc.isEmpty {
                Text(desc)
                    .font(.system(size: AppFontSize.base, weight: .medium))
                    .foregroundStyle(AppColors.textSecond)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: AppSpacing.sm) {
                Image(systemName: playlist.isPublic ? "globe" : "lock.fill")
                    .font(.system(size: 11, weight: .bold))
                Text(l10n.t(playlist.isPublic ? "library.public" : "library.private"))
                    .font(.system(size: AppFontSize.sm, weight: .bold))
                Text("·")
                Text(l10n.t("library.trackCount").replacingOccurrences(of: "%@", with: "\(tracks.count)"))
                    .font(.system(size: AppFontSize.sm, weight: .bold))
            }
            .foregroundStyle(AppColors.textMuted)
        }
    }

    private var playAllButton: some View {
        Button {
            if let first = tracks.first {
                MusicPlayer.shared.load(track: first)
            }
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
        .disabled(tracks.isEmpty)
        .opacity(tracks.isEmpty ? 0.5 : 1)
    }

    @ViewBuilder
    private var tracksList: some View {
        if isLoading {
            VStack(spacing: AppSpacing.sm) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .fill(AppColors.card)
                        .frame(height: 64)
                }
            }
        } else if tracks.isEmpty {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(AppColors.textMuted)
                Text(l10n.t("library.playlistEmpty"))
                    .font(.system(size: AppFontSize.base, weight: .semibold))
                    .foregroundStyle(AppColors.textMuted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.xxl)
        } else {
            VStack(spacing: AppSpacing.sm) {
                ForEach(tracks) { track in
                    Button {
                        MusicPlayer.shared.load(track: track)
                    } label: {
                        LibraryTrackRow(
                            track: track,
                            isCurrent: MusicPlayer.shared.currentTrack?.id == track.id
                        )
                    }
                    .buttonStyle(PressableScaleStyle())
                }
            }
        }
    }

    private func load() async {
        tracks = (try? await PlaylistService.shared.fetchTracks(playlistId: playlist.id)) ?? []
        covers = tracks.prefix(4).compactMap { $0.thumbnailUrl }
        isLoading = false
    }
}
