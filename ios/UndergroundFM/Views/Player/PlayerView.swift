//
//  PlayerView.swift
//  UndergroundFM
//
//  Full-screen Spotify-style player presented as a sheet.
//  Shows album art, metadata, like/share, scrubber, and transport controls.
//

import SwiftUI
import AVKit

struct PlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var player: MusicPlayer = .shared
    @Bindable var l10n: L10n = .shared
    /// Tik op de artiestennaam → sluit de player en open publiek artiestenprofiel.
    var onTapArtist: (ArtistRoute) -> Void = { _ in }

    @State private var isScrubbing: Bool = false
    @State private var scrubValue: TimeInterval = 0
    @State private var selectedTab: PlayerTab = .audio
    @State private var isLiked: Bool = false
    @State private var likeBusy: Bool = false
    @State private var isShuffle: Bool = false
    @State private var isRepeat: Bool = false

    private enum PlayerTab { case audio, clip }

    private var hasClip: Bool {
        guard let v = player.currentTrack?.videoUrl else { return false }
        return !v.isEmpty
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                tabSwitcher
                    .padding(.top, AppSpacing.sm)

                if selectedTab == .clip {
                    clipContent
                } else {
                    audioContent
                }
            }
        }
        .task(id: player.currentTrack?.id) { await loadLikeState() }
        .onChange(of: hasClip) { _, has in
            if !has { selectedTab = .audio }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(l10n.t("feed.featured"))
                .font(.system(size: AppFontSize.xs, weight: .black))
                .tracking(2)
                .foregroundStyle(AppColors.textMuted)

            Spacer()

            // Symmetrie-spacer
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.sm)
    }

    // MARK: - Tab switcher

    private var tabSwitcher: some View {
        HStack(spacing: AppSpacing.sm) {
            tabButton(title: "🎧 " + l10n.t("player.audio"), tab: .audio)
            if hasClip {
                tabButton(title: "🎬 " + l10n.t("player.clip"), tab: .clip)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
    }

    private func tabButton(title: String, tab: PlayerTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        } label: {
            Text(title)
                .font(.system(size: AppFontSize.sm, weight: .bold))
                .foregroundStyle(selectedTab == tab ? AppColors.yellowText : AppColors.textSecond)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, 8)
                .background(selectedTab == tab ? AppColors.yellow : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Audio content

    private var audioContent: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer(minLength: AppSpacing.lg)

            albumArt

            metadata

            actionRow

            scrubber

            controls

            Spacer(minLength: AppSpacing.lg)
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.bottom, AppSpacing.xl)
    }

    private var albumArt: some View {
        AppColors.card
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                artworkImage.allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .shadow(color: .black.opacity(0.7), radius: 28, y: 16)
            .shadow(color: AppColors.yellow.opacity(0.12), radius: 24, y: 8)
            .padding(.horizontal, AppSpacing.md)
    }

    @ViewBuilder
    private var artworkImage: some View {
        if let urlStr = player.currentTrack?.thumbnailUrl, let url = URL(string: urlStr) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().aspectRatio(contentMode: .fill)
                default:
                    fallbackArt
                }
            }
        } else {
            fallbackArt
        }
    }

    private var fallbackArt: some View {
        Image(systemName: "music.note")
            .font(.system(size: 60, weight: .bold))
            .foregroundStyle(AppColors.textMuted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Metadata

    private var metadata: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(player.currentTrack?.title ?? l10n.t("player.noTrack"))
                .font(.system(size: AppFontSize.lg, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Button {
                guard let track = player.currentTrack else { return }
                onTapArtist(ArtistRoute(artistId: track.artistId, artistName: track.artistName))
            } label: {
                Text(player.currentTrack?.artistName ?? "")
                    .font(.system(size: AppFontSize.md, weight: .semibold))
                    .foregroundStyle(AppColors.yellow)
                    .lineLimit(1)
            }
            .buttonStyle(.plain)
            .disabled(player.currentTrack == nil)

            playCountBadge
        }
    }

    @ViewBuilder
    private var playCountBadge: some View {
        if let track = player.currentTrack {
            HStack(spacing: 5) {
                Image(systemName: "play.fill")
                    .font(.system(size: 9, weight: .black))
                Text("\(formatCount(track.streamCount)) \(l10n.t("player.plays"))")
                    .font(.system(size: AppFontSize.xs, weight: .bold))
            }
            .foregroundStyle(AppColors.textMuted)
            .padding(.top, 2)
        }
    }

    // MARK: - Action row

    private var actionRow: some View {
        HStack {
            Button {
                Task { await toggleLike() }
            } label: {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isLiked ? AppColors.yellow : AppColors.textSecond)
                    .frame(width: 44, height: 44)
                    .scaleEffect(isLiked ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isLiked)
            }
            .buttonStyle(.plain)
            .disabled(likeBusy || player.currentTrack == nil)

            Spacer()

            if player.currentTrack?.explicit == true {
                Text("🅴")
                    .font(.system(size: 20))
                    .accessibilityLabel("Explicit")
            }

            Spacer()

            ShareLink(item: shareText) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(AppColors.textSecond)
                    .frame(width: 44, height: 44)
            }
            .disabled(player.currentTrack == nil)
        }
    }

    private var shareText: String {
        let title = player.currentTrack?.title ?? ""
        let artist = player.currentTrack?.artistName ?? ""
        let message = String(format: l10n.t("player.shareText"), title, artist)
        guard let id = player.currentTrack?.id else { return message }
        return "\(message)\n\nundergroundfm://track/\(id)"
    }

    // MARK: - Scrubber

    private var scrubber: some View {
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
                if newValue { scrubValue = player.currentTime }
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
    }

    // MARK: - Controls

    private var controls: some View {
        HStack {
            Button {
                isShuffle.toggle()
            } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isShuffle ? AppColors.yellow : AppColors.textSecond)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                player.skipBackward()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                player.togglePlayPause()
            } label: {
                ZStack {
                    Circle()
                        .fill(AppColors.yellow)
                        .frame(width: 72, height: 72)
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 30, weight: .black))
                        .foregroundStyle(AppColors.yellowText)
                        .offset(x: player.isPlaying ? 0 : 2)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                player.skipForward()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                isRepeat.toggle()
            } label: {
                Image(systemName: isRepeat ? "repeat.1" : "repeat")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isRepeat ? AppColors.yellow : AppColors.textSecond)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Clip content

    @ViewBuilder
    private var clipContent: some View {
        if let urlStr = player.currentTrack?.videoUrl, !urlStr.isEmpty, let url = URL(string: urlStr) {
            VStack(spacing: AppSpacing.lg) {
                Spacer()
                ClipPlayerView(url: url)
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.6), radius: 20, y: 10)

                if let title = player.currentTrack?.title {
                    Text(title)
                        .font(.system(size: AppFontSize.md, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, AppSpacing.lg)
        } else {
            clipPlaceholder
        }
    }

    // MARK: - Clip placeholder

    private var clipPlaceholder: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Image(systemName: "film.stack")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
            Text(l10n.t("player.clipSoon"))
                .font(.system(size: AppFontSize.lg, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
            Text(l10n.t("player.clipSoonSub"))
                .font(.system(size: AppFontSize.sm, weight: .medium))
                .foregroundStyle(AppColors.textMuted)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, AppSpacing.xl)
    }

    // MARK: - Like

    private func loadLikeState() async {
        isLiked = false
        guard let track = player.currentTrack,
              let userId = SessionStore.shared.session?.userId else { return }
        isLiked = (try? await LikesService.shared.isLiked(trackId: track.id, userId: userId)) ?? false
    }

    private func toggleLike() async {
        guard let track = player.currentTrack,
              let userId = SessionStore.shared.session?.userId,
              !likeBusy else { return }
        likeBusy = true
        defer { likeBusy = false }
        let wasLiked = isLiked
        isLiked.toggle()
        do {
            if wasLiked {
                try await LikesService.shared.unlike(trackId: track.id, userId: userId)
            } else {
                try await LikesService.shared.like(trackId: track.id, userId: userId)
            }
        } catch {
            isLiked = wasLiked
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, !seconds.isNaN else { return "0:00" }
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}
