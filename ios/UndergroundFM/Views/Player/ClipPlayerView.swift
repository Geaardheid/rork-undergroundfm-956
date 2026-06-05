//
//  ClipPlayerView.swift
//  UndergroundFM
//
//  16:9 videoclip-speler. De video is een volwaardige, alternatieve bron van
//  dezelfde track: hij heeft zijn eigen geluid en wordt aangestuurd door
//  MusicPlayer.shared. Deze view rendert alleen de actieve videobron — er is
//  geen aparte, gedempte sync-speler meer.
//

import SwiftUI
import AVKit

struct ClipPlayerView: View {
    @Bindable private var music: MusicPlayer = .shared
    @State private var showControls: Bool = true

    var body: some View {
        ZStack {
            if let player = music.videoRenderPlayer {
                VideoPlayerLayerView(player: player)
            } else {
                Color.black
            }

            // Tik om controls te tonen/verbergen.
            Color.black.opacity(0.001)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) { showControls.toggle() }
                }

            if music.isSwitchingSource {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.3)
            } else if showControls {
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
        .onAppear { OrientationManager.shared.allowLandscape() }
        .onDisappear { OrientationManager.shared.lockPortrait() }
        // Verberg de controls automatisch zodra de video speelt.
        .onChange(of: music.isPlaying) { _, playing in
            if playing {
                withAnimation(.easeInOut(duration: 0.3).delay(0.8)) { showControls = false }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) { showControls = true }
            }
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
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
    }
}

private final class PlayerLayerUIView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}
