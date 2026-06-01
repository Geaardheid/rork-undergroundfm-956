//
//  PlayerView.swift
//  UndergroundFM
//
//  Full-screen audio player presented as a sheet.
//  Shows album art, track metadata, progress scrubber, and controls.
//

import SwiftUI

struct PlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var player: MusicPlayer = .shared
    @State private var isScrubbing: Bool = false
    @State private var scrubValue: TimeInterval = 0

    var body: some View {
        ZStack {
            AppColors.bg.ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                // Drag handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppColors.textMuted.opacity(0.5))
                    .frame(width: 36, height: 5)
                    .padding(.top, AppSpacing.sm)

                Spacer().frame(height: AppSpacing.xl)

                // Album art
                albumArt

                // Track info
                VStack(spacing: AppSpacing.xs) {
                    Text(player.currentTrack?.title ?? "")
                        .font(.system(size: AppFontSize.xl, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    Text(player.currentTrack?.artistName ?? "")
                        .font(.system(size: AppFontSize.md, weight: .medium))
                        .foregroundStyle(AppColors.textSecond)
                        .lineLimit(1)
                }
                .padding(.horizontal, AppSpacing.xxl)

                // Progress
                VStack(spacing: AppSpacing.sm) {
                    Slider(
                        value: isScrubbing ? $scrubValue : Binding(
                            get: { player.currentTime },
                            set: { player.seek(to: $0) }
                        ),
                        in: 0...max(player.duration, 1),
                        onEditingChanged: { editing in
                            isScrubbing = editing
                            if !editing {
                                player.seek(to: scrubValue)
                            }
                        }
                    )
                    .tint(AppColors.yellow)
                    .onChange(of: isScrubbing) { _, newValue in
                        if newValue {
                            scrubValue = player.currentTime
                        }
                    }

                    HStack {
                        Text(isScrubbing ? formatTime(scrubValue) : player.formattedCurrentTime)
                            .font(.system(size: AppFontSize.xs, weight: .medium).monospacedDigit())
                            .foregroundStyle(AppColors.textMuted)

                        Spacer()

                        Text(player.formattedDuration)
                            .font(.system(size: AppFontSize.xs, weight: .medium).monospacedDigit())
                            .foregroundStyle(AppColors.textMuted)
                    }
                }
                .padding(.horizontal, AppSpacing.xl)

                // Playback controls
                HStack(spacing: AppSpacing.xxl) {
                    // Skip back
                    Button {
                        player.skipBackward()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    .buttonStyle(.plain)

                    // Play/pause
                    Button {
                        player.togglePlayPause()
                    } label: {
                        Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64, weight: .medium))
                            .foregroundStyle(AppColors.yellow)
                    }
                    .buttonStyle(.plain)

                    // Skip forward
                    Button {
                        player.skipForward()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Close button
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.textSecond)
                        .frame(width: 44, height: 44)
                        .background(AppColors.card, in: Circle())
                }
                .buttonStyle(.plain)
                .padding(.bottom, AppSpacing.xl)
            }
        }
    }

    // MARK: - Album art

    private var albumArt: some View {
        Group {
            if let urlStr = player.currentTrack?.thumbnailUrl,
               let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        fallbackArt
                    }
                }
            } else {
                fallbackArt
            }
        }
        .frame(width: 260, height: 260)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(color: AppColors.yellow.opacity(0.15), radius: 20, y: 10)
    }

    private var fallbackArt: some View {
        Image(systemName: "music.note")
            .font(.system(size: 60, weight: .bold))
            .foregroundStyle(AppColors.textMuted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.card)
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, !seconds.isNaN else { return "0:00" }
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}
