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
    @State private var statusObserver: NSKeyValueObservation?
    @State private var didStartSyncedPlayback: Bool = false

    /// Maximaal toegestane drift (s) voordat de video opnieuw wordt gesynct.
    private let driftTolerance: TimeInterval = 0.25
    @State private var lastSyncTime: TimeInterval = 0

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
        .onAppear {
            OrientationManager.shared.allowLandscape()
            startSync()
        }
        .onDisappear {
            OrientationManager.shared.lockPortrait()
            stopSync()
        }
        // Volg play/pause van de audio.
        .onChange(of: music.isPlaying) { _, playing in
            guard didStartSyncedPlayback else { return }
            if playing { player.play() } else { player.pause() }
            if playing {
                withAnimation(.easeInOut(duration: 0.3).delay(0.8)) { showControls = false }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) { showControls = true }
            }
        }
        // Volg seeks van de audio (scrubber, skip, remote commands).
        .onChange(of: music.currentTime) { _, _ in
            guard didStartSyncedPlayback else { return }
            correctDriftIfNeeded()
        }
    }

    // MARK: - Sync

    /// Bij het openen van de Clip-tab: pauzeer de audio, wacht tot de video klaar is om
    /// af te spelen, seek de video naar de exacte audiopositie en hervat daarna audio en
    /// video op exact hetzelfde moment. Zo kan de video niet achterlopen door laadtijd.
    private func startSync() {
        didStartSyncedPlayback = false
        let resume = music.isPlaying

        // 1. Pauzeer de audio zolang de video buffert, zodat ze niet uit elkaar lopen.
        music.pause()

        // 2. Wacht tot het video-item klaar is om af te spelen.
        if let item = player.currentItem, item.status == .readyToPlay {
            beginSyncedPlayback(resume: resume)
        } else {
            statusObserver = player.currentItem?.observe(\.status, options: [.new]) { item, _ in
                guard item.status == .readyToPlay else { return }
                Task { @MainActor in
                    self.statusObserver?.invalidate()
                    self.statusObserver = nil
                    self.beginSyncedPlayback(resume: resume)
                }
            }
        }

        // Periodieke observer corrigeert kleine drift tijdens het afspelen.
        let interval = CMTime(seconds: 1.0, preferredTimescale: 600)
        syncObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { _ in
            guard didStartSyncedPlayback else { return }
            correctDriftIfNeeded()
        }
    }

    /// Seek de video naar de huidige audiopositie en hervat (indien nodig) beide samen.
    private func beginSyncedPlayback(resume: Bool) {
        let target = CMTime(seconds: max(music.currentTime, 0), preferredTimescale: 600)
        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
            Task { @MainActor in
                self.didStartSyncedPlayback = true
                if resume {
                    // 3. Hervat audio en video op exact hetzelfde moment.
                    self.player.play()
                    self.music.play()
                    withAnimation(.easeInOut(duration: 0.3).delay(0.8)) { self.showControls = false }
                } else {
                    self.player.pause()
                }
            }
        }
    }

    /// Bij het verlaten van de Clip-tab: pauzeer de video, sync de audio naar de huidige
    /// videopositie en hervat de audio (indien die speelde).
    private func stopSync() {
        if let obs = syncObserver {
            player.removeTimeObserver(obs)
            syncObserver = nil
        }
        statusObserver?.invalidate()
        statusObserver = nil

        let wasPlaying = music.isPlaying
        player.pause()

        let videoTime = player.currentTime().seconds
        if videoTime.isFinite, didStartSyncedPlayback {
            // music.seek behoudt de afspeelstatus; audio loopt dus door als 'ie speelde.
            music.seek(to: max(videoTime, 0))
            if wasPlaying && !music.isPlaying { music.play() }
        }
        didStartSyncedPlayback = false
    }

    /// Reseek alleen als de video te ver van de audio afdrijft.
    private func correctDriftIfNeeded() {
        let videoTime = player.currentTime().seconds
        guard videoTime.isFinite else { return }
        let drift = abs(videoTime - music.currentTime)
        guard abs(music.currentTime - lastSyncTime) > 0.5 || drift > 1.0 else { return }
        if drift > driftTolerance {
            let target = CMTime(seconds: max(music.currentTime, 0), preferredTimescale: 600)
            player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
            lastSyncTime = music.currentTime
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
