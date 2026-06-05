//
//  MusicPlayer.swift
//  UndergroundFM
//
//  Singleton audio player using AVPlayer for streaming.
//  Exposes playback state as @Observable for SwiftUI binding.
//

import AVFoundation
import MediaPlayer
import Observation
import UIKit

@Observable
final class MusicPlayer {
    static let shared = MusicPlayer()

    var currentTrack: Track?
    var isPlaying: Bool = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0

    // MARK: - Queue
    var queue: [Track] = []
    var currentQueueIndex: Int = 0

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var artworkTask: Task<Void, Never>?

    private init() {
        configureAudioSession()
        setupRemoteCommands()
        setupInterruptionObserver()
    }

    /// Configure the shared audio session for background playback.
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: []
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    /// Handle audio session interruptions (calls, Siri, other apps).
    /// On `.began` we pause; on `.ended` we resume only when the system
    /// flags `shouldResume`. This is the only place playback reacts to
    /// app/system lifecycle — nothing pauses on foreground/`.active`.
    private func setupInterruptionObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let rawType = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: rawType) else {
            return
        }

        switch type {
        case .began:
            if isPlaying { pause() }
        case .ended:
            guard let rawOptions = info[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
            if options.contains(.shouldResume) {
                try? AVAudioSession.sharedInstance().setActive(true)
                play()
            }
        @unknown default:
            break
        }
    }

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

    // MARK: - Queue

    /// Set the full queue and immediately start the track at `index`.
    func setQueue(_ tracks: [Track], startingAt index: Int) {
        guard !tracks.isEmpty, index >= 0, index < tracks.count else { return }
        queue = tracks
        currentQueueIndex = index
        loadFromQueue(tracks[index])
    }

    /// Advance to the next track in the queue, if one exists.
    func playNext() {
        let next = currentQueueIndex + 1
        guard next < queue.count else { return }
        currentQueueIndex = next
        loadFromQueue(queue[next])
    }

    /// Go to the previous track in the queue, if one exists.
    func playPrevious() {
        let prev = currentQueueIndex - 1
        guard prev >= 0, prev < queue.count else { return }
        currentQueueIndex = prev
        loadFromQueue(queue[prev])
    }

    // MARK: - Load

    func load(track: Track) {
        if currentTrack?.id == track.id {
            togglePlayPause()
            return
        }
        // Direct single-track playback still behaves as a one-item queue.
        queue = [track]
        currentQueueIndex = 0
        loadFromQueue(track)
    }

    /// Internal loader shared by queue and direct playback. Does not touch
    /// `queue`/`currentQueueIndex` so callers control queue semantics.
    private func loadFromQueue(_ track: Track) {
        clear()

        guard let urlStr = track.audioUrl, let url = URL(string: urlStr) else { return }

        currentTrack = track
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        duration = TimeInterval(track.duration ?? 0)

        observe(playerItem: item)
        play()
        updateNowPlayingInfo()
        loadArtwork(from: track.thumbnailUrl)

        if let uid = SessionStore.shared.session?.userId {
            ViewTracker.shared.startSession(track: track, userId: uid)
        }
    }

    // MARK: - Playback controls

    func play() {
        player?.play()
        isPlaying = true
        updateNowPlayingPlaybackState()
    }

    func pause() {
        ViewTracker.shared.endSession()
        player?.pause()
        isPlaying = false
        updateNowPlayingPlaybackState()
    }

    func togglePlayPause() {
        if isPlaying { pause() } else { play() }
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = time
        updateNowPlayingPlaybackState()
    }

    func skipForward(seconds: TimeInterval = 15) {
        seek(to: min(currentTime + seconds, duration))
    }

    func skipBackward(seconds: TimeInterval = 15) {
        seek(to: max(currentTime - seconds, 0))
    }

    func clear() {
        ViewTracker.shared.endSession()
        removeObservers()
        artworkTask?.cancel()
        artworkTask = nil
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        currentTrack = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - Private

    private func observe(playerItem: AVPlayerItem) {
        let scale = CMTimeScale(600)
        let interval = CMTime(seconds: 0.25, preferredTimescale: scale)

        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            self.currentTime = time.seconds
            ViewTracker.shared.tick(currentTime: time.seconds, duration: self.duration)

            // Preview-modus: niet-abonnees mogen maar 30s per track horen.
            // Centrale cutoff op spelerniveau — werkt voor audio, mini player en clip.
            if !SubscriptionService.shared.isSubscribed && self.currentTime >= 30 {
                self.pause()
                SubscriptionService.shared.showPaywall = true
            }
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
            guard let self else { return }
            ViewTracker.shared.endSession()
            // Auto-advance to the next queued track; stop if this was the last.
            if self.currentQueueIndex + 1 < self.queue.count {
                self.playNext()
            } else {
                self.isPlaying = false
                self.currentTime = 0
            }
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

    // MARK: - Now Playing & Remote Commands

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.isEnabled = true
        center.playCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            if !self.isPlaying { self.play() }
            return .success
        }

        center.pauseCommand.isEnabled = true
        center.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            if self.isPlaying { self.pause() }
            return .success
        }

        center.togglePlayPauseCommand.isEnabled = true
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.togglePlayPause()
            return .success
        }

        center.nextTrackCommand.isEnabled = true
        center.nextTrackCommand.addTarget { [weak self] _ in
            guard let self, self.currentTrack != nil else { return .commandFailed }
            guard self.currentQueueIndex + 1 < self.queue.count else { return .noSuchContent }
            self.playNext()
            return .success
        }

        center.previousTrackCommand.isEnabled = true
        center.previousTrackCommand.addTarget { [weak self] _ in
            guard let self, self.currentTrack != nil else { return .commandFailed }
            guard self.currentQueueIndex - 1 >= 0 else { return .noSuchContent }
            self.playPrevious()
            return .success
        }

        center.changePlaybackPositionCommand.isEnabled = true
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self,
                  let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.seek(to: event.positionTime)
            return .success
        }
    }

    /// Refresh the full Now Playing entry (title, artist, duration).
    private func updateNowPlayingInfo() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
        info[MPMediaItemPropertyTitle] = track.title
        info[MPMediaItemPropertyArtist] = track.artistName
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        if track.explicit {
            info[MPMediaItemPropertyIsExplicit] = true
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    /// Update only the elapsed time + playback rate (cheap, called often).
    private func updateNowPlayingPlaybackState() {
        guard currentTrack != nil else { return }
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        info[MPMediaItemPropertyPlaybackDuration] = duration
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    /// Fetch the cover art and attach it as lock screen artwork.
    private func loadArtwork(from urlString: String?) {
        artworkTask?.cancel()
        guard let urlString, let url = URL(string: urlString) else { return }
        artworkTask = Task { [weak self] in
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = UIImage(data: data) else { return }
            if Task.isCancelled { return }
            await MainActor.run {
                guard let self, self.currentTrack?.thumbnailUrl == urlString else { return }
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
                info[MPMediaItemPropertyArtwork] = artwork
                MPNowPlayingInfoCenter.default().nowPlayingInfo = info
            }
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, !seconds.isNaN else { return "0:00" }
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}
