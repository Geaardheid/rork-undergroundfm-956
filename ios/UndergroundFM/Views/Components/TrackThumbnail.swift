//
//  TrackThumbnail.swift
//  UndergroundFM
//

import SwiftUI

/// Square 1:1 thumbnail met fallback (gele highlight optie zoals in mockup).
struct TrackThumbnail: View {
    let url: String?
    var highlighted: Bool = false
    var cornerRadius: CGFloat = AppRadius.md
    /// Toon een geanimeerde play/pause-overlay als deze track de huidige is.
    var isCurrent: Bool = false
    var isPlaying: Bool = false
    /// Toon een 🎬 badge rechtsonder als de track een videoclip heeft.
    var hasVideo: Bool = false

    var body: some View {
        Color(highlighted ? AppColors.yellow : AppColors.card)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let urlStr = url, let u = URL(string: urlStr) {
                    AsyncImage(url: u) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable()
                                .aspectRatio(1, contentMode: .fill)
                                .clipped()
                                .allowsHitTesting(false)
                        default:
                            placeholderIcon
                        }
                    }
                } else {
                    placeholderIcon
                }
            }
            .overlay { if isCurrent { playingOverlay } }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(alignment: .bottomTrailing) { if hasVideo { videoBadge } }
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(isCurrent ? AppColors.yellow : (highlighted ? AppColors.yellow : AppColors.border), lineWidth: isCurrent ? 2 : 1)
            )
    }

    private var videoBadge: some View {
        Text("🎬")
            .font(.system(size: 11))
            .padding(5)
            .background(.black.opacity(0.6))
            .clipShape(Circle())
            .padding(6)
            .allowsHitTesting(false)
    }

    private var playingOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
            PlayingIndicator(isPlaying: isPlaying)
        }
        .allowsHitTesting(false)
    }

    private var placeholderIcon: some View {
        Image(systemName: "music.note")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(highlighted ? AppColors.yellowText.opacity(0.5) : AppColors.textMuted)
    }
}

/// Toont een geanimeerde equalizer als de track speelt, of een pauze-icoon.
struct PlayingIndicator: View {
    let isPlaying: Bool
    @State private var animate: Bool = false

    var body: some View {
        Group {
            if isPlaying {
                HStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { i in
                        Capsule()
                            .fill(AppColors.yellow)
                            .frame(width: 4, height: animate ? barHeight(i) : 6)
                            .animation(
                                .easeInOut(duration: 0.45)
                                    .repeatForever()
                                    .delay(Double(i) * 0.12),
                                value: animate
                            )
                    }
                }
                .frame(height: 26, alignment: .center)
                .onAppear { animate = true }
            } else {
                Image(systemName: "play.fill")
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(AppColors.yellow)
            }
        }
        .shadow(color: .black.opacity(0.5), radius: 4)
    }

    private func barHeight(_ index: Int) -> CGFloat {
        let heights: [CGFloat] = [22, 14, 26, 18]
        return heights[index % heights.count]
    }
}
