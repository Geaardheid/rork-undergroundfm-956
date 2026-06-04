//
//  ClipPlayerView.swift
//  UndergroundFM
//
//  16:9 videoclip-speler met play/pause controls (AVPlayer).
//

import SwiftUI
import AVKit

struct ClipPlayerView: View {
    let url: URL

    @State private var player: AVPlayer
    @State private var isPlaying: Bool = false
    @State private var showControls: Bool = true

    init(url: URL) {
        self.url = url
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        ZStack {
            VideoPlayerLayerView(player: player)

            // Tap om controls te tonen/verbergen.
            Color.black.opacity(0.001)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) { showControls.toggle() }
                }

            if showControls {
                Button {
                    togglePlayPause()
                } label: {
                    ZStack {
                        Circle()
                            .fill(.black.opacity(0.45))
                            .frame(width: 64, height: 64)
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 26, weight: .black))
                            .foregroundStyle(.white)
                            .offset(x: isPlaying ? 0 : 2)
                    }
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .onDisappear {
            player.pause()
            isPlaying = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { _ in
            player.seek(to: .zero)
            isPlaying = false
            withAnimation(.easeInOut(duration: 0.2)) { showControls = true }
        }
    }

    private func togglePlayPause() {
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
        if isPlaying {
            // Verberg de controls kort na het starten.
            withAnimation(.easeInOut(duration: 0.3).delay(0.8)) { showControls = false }
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
