//
//  GenreRow.swift
//  UndergroundFM
//

import SwiftUI

struct GenreRow: View {
    let section: GenreSection
    let state: FeedStore.SectionState
    @Bindable var l10n: L10n
    var onSelectTrack: (Track) -> Void = { _ in }
    var onSelectArtist: (Track) -> Void = { _ in }
    var onRetry: () -> Void = {}
    var onSeeAll: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Text(section.emoji)
                        .font(.system(size: AppFontSize.lg))
                    Text(l10n.t(section.titleKey))
                        .font(.system(size: AppFontSize.md, weight: .black))
                        .foregroundStyle(AppColors.yellow)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                Spacer()
                Button(action: onSeeAll) {
                    HStack(spacing: 4) {
                        Text(l10n.t("feed.seeAll"))
                            .font(.system(size: AppFontSize.sm, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(AppColors.textSecond)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppSpacing.lg)

            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .idle, .loading:
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(0..<4, id: \.self) { _ in
                        TrackCardSkeleton(width: 150)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        case .loaded(let tracks):
            if tracks.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: AppSpacing.md) {
                        ForEach(Array(tracks.enumerated()), id: \.element.id) { idx, track in
                            TrackCard(
                                track: track,
                                highlighted: idx == 0,
                                width: 132,
                                isCurrent: MusicPlayer.shared.currentTrack?.id == track.id,
                                isPlaying: MusicPlayer.shared.isPlaying,
                                onTap: { onSelectTrack(track) },
                                onTapArtist: { onSelectArtist(track) }
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
            }
        case .error(let message):
            errorState(message: message)
        }
    }

    private var emptyState: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "music.note")
                .font(.system(size: 16))
                .foregroundStyle(AppColors.textMuted)
            Text(l10n.t("feed.emptyGenre"))
                .font(.system(size: AppFontSize.sm, weight: .medium))
                .foregroundStyle(AppColors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.lg)
    }

    private func errorState(message: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppColors.warning)
            VStack(alignment: .leading, spacing: 2) {
                Text(l10n.t("feed.errorTitle"))
                    .font(.system(size: AppFontSize.sm, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                Text(message)
                    .font(.system(size: AppFontSize.xs))
                    .foregroundStyle(AppColors.textMuted)
                    .lineLimit(2)
            }
            Spacer()
            Button(action: onRetry) {
                Text(l10n.t("feed.retry"))
                    .font(.system(size: AppFontSize.sm, weight: .bold))
                    .foregroundStyle(AppColors.yellow)
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .padding(.horizontal, AppSpacing.lg)
    }
}
