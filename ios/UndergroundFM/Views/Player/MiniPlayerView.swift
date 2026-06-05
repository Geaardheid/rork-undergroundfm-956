//
//  MiniPlayerView.swift
//  UndergroundFM
//
//  Persistent mini player bar pinned above the tab bar.
//  Shown whenever MusicPlayer.shared.hasTrack is true.
//

import SwiftUI

struct MiniPlayerView: View {
    @Bindable var player: MusicPlayer
    @Binding var showFullPlayer: Bool

    /// Preview-grens bereikt voor een niet-abonnee: toon een slot i.p.v. afspelen.
    private var isLocked: Bool {
        !SubscriptionService.shared.isSubscribed && player.currentTime >= 29.5
    }

    var body: some View {
        if player.hasTrack {
            VStack(spacing: 0) {
                // Progress bar (2px, yellow)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        AppColors.border.frame(height: 2)
                        AppColors.yellow
                            .frame(width: geo.size.width * player.progress, height: 2)
                    }
                }
                .frame(height: 2)

                // Player bar
                Button {
                    if isLocked {
                        SubscriptionService.shared.showPaywall = true
                    } else {
                        showFullPlayer = true
                    }
                } label: {
                    HStack(spacing: AppSpacing.md) {
                        // Album artwork
                        artwork

                        // Track info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(player.currentTrack?.title ?? "")
                                .font(.system(size: AppFontSize.sm, weight: .bold))
                                .foregroundStyle(AppColors.textPrimary)
                                .lineLimit(1)

                            Text(player.currentTrack?.artistName ?? "")
                                .font(.system(size: AppFontSize.xs, weight: .medium))
                                .foregroundStyle(AppColors.textSecond)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if isLocked {
                            // Slot: opent de paywall.
                            Button {
                                SubscriptionService.shared.showPaywall = true
                            } label: {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(AppColors.yellow)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                        } else {
                            // Play/pause
                            Button {
                                player.togglePlayPause()
                            } label: {
                                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(AppColors.yellow)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)

                            // Skip forward
                            Button {
                                player.skipForward()
                            } label: {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(AppColors.textSecond)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
                }
                .buttonStyle(.plain)
            }
            .frame(height: 64)
            .background(AppColors.card)
            .overlay(
                Rectangle()
                    .fill(AppColors.border)
                    .frame(height: 1),
                alignment: .top
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Album artwork

    @ViewBuilder
    private var artwork: some View {
        Group {
            if let urlStr = player.currentTrack?.thumbnailUrl,
               let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable()
                            .aspectRatio(1, contentMode: .fill)
                    default:
                        fallbackArtwork
                    }
                }
            } else {
                fallbackArtwork
            }
        }
        .frame(width: 40, height: 40)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .stroke(AppColors.borderLight, lineWidth: 1)
        )
    }

    private var fallbackArtwork: some View {
        Image(systemName: "music.note")
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(AppColors.textMuted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.cardHover)
    }
}
