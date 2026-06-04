//
//  ClipPlayerView.swift
//  UndergroundFM
//
//  16:9 videoclip-speler die synchroon loopt met de audio van MusicPlayer.
//  De video volgt MusicPlayer.shared: zelfde positie, play/pause en seeks.
//  De videosporen zijn gedempt — geluid komt uitsluitend van MusicPlayer.
//

import SwiftUI
import AVKit

struct ClipPlayerView: View {
    let url: URL

    @Bindable private var music: MusicPlayer = .shared

    @State private var player: AVPlayer
    @State private var showControls: Bool = true
    @State private var syncObserver: Any?

    /// Maximaal toegestane drift (s) voordat de video opnieuw wordt gesynct.
    private let driftTolerance: TimeInterval = 0.35

    init(url: URL) {
        self.url = url
        let avPlayer = AVPlayer(url: url)
        avPlayer.isMuted = true
        _player = State(initialValue: avPlayer)
    }

    var body: some View {
        ZStack {
            VideoPlayerLayerView(player: player)

            // Tik om controls te tonen/verbergen.
            Color.black.opacity(0.001)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) { showControls.toggle() }
                }

            if showControls {
                Button {
                    music.togglePlayPause()
                } label: {
                    ZStack {
                        Circle()
                            .fill(.black.opacity(0.45))
                            .frame(width: 64, height: 64)
                        Image(systemName: music.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 26, weight: .black))
                            .foregroundStyle(.white)
                            .offset(x: music.isPlaying ? 0 : 2)
                    }
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .onAppear { startSync() }
        .onDisappear { stopSync() }
        // Volg play/pause van de audio.
        .onChange(of: music.isPlaying) { _, playing in
            syncToAudio(forceSeek: false)
            if playing {
                withAnimation(.easeInOut(duration: 0.3).delay(0.8)) { showControls = false }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) { showControls = true }
            }
        }
        // Volg seeks van de audio (scrubber, skip, remote commands).
        .onChange(of: music.currentTime) { _, _ in
            correctDriftIfNeeded()
        }
    }

    // MARK: - Sync

    /// Synchroniseer de videopositie en -status bij het openen van de Clip-tab.
    private func startSync() {
        syncToAudio(forceSeek: true)

        // Periodieke observer corrigeert kleine drift tijdens het afspelen.
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        syncObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { _ in
            correctDriftIfNeeded()
        }
    }

    private func stopSync() {
        if let obs = syncObserver {
            player.removeTimeObserver(obs)
            syncObserver = nil
        }
        player.pause()
    }

    /// Zet de video op de exacte audiopositie en match de afspeelstatus.
    private func syncToAudio(forceSeek: Bool) {
        let target = CMTime(seconds: max(music.currentTime, 0), preferredTimescale: 600)
        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
            if music.isPlaying {
                player.play()
            } else {
                player.pause()
            }
        }
        if !forceSeek {
            if music.isPlaying { player.play() } else { player.pause() }
        }
    }

    /// Reseek alleen als de video te ver van de audio afdrijft.
    private func correctDriftIfNeeded() {
        let videoTime = player.currentTime().seconds
        guard videoTime.isFinite else { return }
        let drift = abs(videoTime - music.currentTime)
        if drift > driftTolerance {
            let target = CMTime(seconds: max(music.currentTime, 0), preferredTimescale: 600)
            player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        // Houd de afspeelstatus in lijn (bv. na bufferen).
        if music.isPlaying && player.timeControlStatus == .paused {
            player.play()
        } else if !music.isPlaying && player.timeControlStatus != .paused {
            player.pause()
        }
    }
}

/// Lichtgewicht UIView-wrapper rond AVPlayerLayer (resizeAspect = 16:9 letterboxing).
private struct VideoPlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerLayerUIView {
        let view = PlayerLayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        return view
    }

    func updateUIView(_ uiView: PlayerLayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }
}

private final class PlayerLayerUIView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}
