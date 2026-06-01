//
//  MusicPlayer.swift
//  UndergroundFM
//
//  Singleton audio player using AVPlayer for streaming.
//  Exposes playback state as @Observable for SwiftUI binding.
//

import AVFoundation
import Observation

@Observable
final class MusicPlayer {
    static let shared = MusicPlayer()

    var currentTrack: Track?
    var isPlaying: Bool = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    var formattedCurrentTime: String {
        formatTime(currentTime)
    }

    var formattedDuration: String {
        formatTime(duration)
    }

    var hasTrack: Bool { currentTrack != nil }

    // MARK: - Load

    func load(track: Track) {
        if currentTrack?.id == track.id {
            togglePlayPause()
            return
        }

        clear()

        guard let urlStr = track.audioUrl, let url = URL(string: urlStr) else { return }

        currentTrack = track
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        duration = TimeInterval(track.duration ?? 0)

        observe(playerItem: item)
        play()
    }

    // MARK: - Playback controls

    func play() {
        player?.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func togglePlayPause() {
        if isPlaying { pause() } else { play() }
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = time
    }

    func skipForward(seconds: TimeInterval = 15) {
        seek(to: min(currentTime + seconds, duration))
    }

    func skipBackward(seconds: TimeInterval = 15) {
        seek(to: max(currentTime - seconds, 0))
    }

    func clear() {
        removeObservers()
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        currentTrack = nil
        isPlaying = false
        currentTime = 0
        duration = 0
    }

    // MARK: - Private

    private func observe(playerItem: AVPlayerItem) {
        let scale = CMTimeScale(600)
        let interval = CMTime(seconds: 0.25, preferredTimescale: scale)

        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            self?.currentTime = time.seconds
        }

        statusObserver = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self else { return }
            if item.status == .readyToPlay {
                let d = item.duration.seconds
                if d.isFinite, !d.isNaN {
                    self.duration = d
                }
            } else if item.status == .failed {
                self.isPlaying = false
            }
        }

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.isPlaying = false
            self?.currentTime = 0
        }
    }

    private func removeObservers() {
        if let obs = timeObserver {
            player?.removeTimeObserver(obs)
            timeObserver = nil
        }
        statusObserver?.invalidate()
        statusObserver = nil
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, !seconds.isNaN else { return "0:00" }
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}
