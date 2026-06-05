//
//  LibraryComponents.swift
//  UndergroundFM
//
//  Visuele bouwstenen voor de vernieuwde Bibliotheek-tab:
//  living hero header, 2×2 snelkoppelingen-grid en de horizontale recent-strook.
//

import SwiftUI

// MARK: - Hero header

/// Levendige header met zwevende cover-collage en overlay-titel.
/// Valt terug op een gele gradient bij minder dan 4 gelikete tracks.
struct LibraryHero: View {
    let coverUrls: [String]
    let title: String
    let onCreate: () -> Void

    private var hasCollage: Bool { coverUrls.count >= 4 }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            background

            LinearGradient(
                colors: [.clear, AppColors.bg.opacity(0.55), AppColors.bg],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            HStack(alignment: .bottom, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title.uppercased())
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(AppColors.yellow)
                        .tracking(1.5)
                    Text(title)
                        .font(.system(size: 40, weight: .black))
                        .foregroundStyle(AppColors.textPrimary)
                        .shadow(color: .black.opacity(0.6), radius: 8, y: 2)
                }
                Spacer(minLength: 0)
                createButton
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
        }
        .frame(height: 230)
        .frame(maxWidth: .infinity)
    }

    private var createButton: some View {
        Button(action: onCreate) {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(AppColors.yellowText)
                .frame(width: 44, height: 44)
                .background(AppColors.yellow)
                .clipShape(Circle())
                .shadow(color: AppColors.yellow.opacity(0.5), radius: 12)
        }
        .buttonStyle(PressableScaleStyle())
    }

    @ViewBuilder
    private var background: some View {
        if hasCollage {
            CoverCollage(urls: Array(coverUrls.prefix(5)))
                .blur(radius: 2)
                .overlay(AppColors.bg.opacity(0.25))
        } else {
            LinearGradient(
                colors: [AppColors.yellow.opacity(0.4), AppColors.cardHover, AppColors.bg],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .overlay(alignment: .topTrailing) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 120, weight: .black))
                    .foregroundStyle(AppColors.yellow.opacity(0.12))
                    .rotationEffect(.degrees(-12))
                    .offset(x: 20, y: -10)
            }
        }
    }
}

/// Verspreide, zwevende covers met fade-in en subtiele drift.
private struct CoverCollage: View {
    let urls: [String]

    // Relatieve posities + rotaties voor maximaal 5 covers.
    private let layout: [(x: CGFloat, y: CGFloat, size: CGFloat, angle: Double, delay: Double)] = [
        (0.18, 0.42, 120, -10, 0.00),
        (0.52, 0.30, 110, 8, 0.10),
        (0.82, 0.50, 116, -6, 0.18),
        (0.34, 0.78, 100, 6, 0.26),
        (0.70, 0.82, 104, -12, 0.34),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
                    let cfg = layout[index % layout.count]
                    DriftingCover(url: url, size: cfg.size, angle: cfg.angle, delay: cfg.delay)
                        .position(x: geo.size.width * cfg.x, y: geo.size.height * cfg.y)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .clipped()
    }
}

private struct DriftingCover: View {
    let url: String
    let size: CGFloat
    let angle: Double
    let delay: Double

    @State private var appeared: Bool = false
    @State private var drift: Bool = false

    var body: some View {
        Color(AppColors.card)
            .frame(width: size, height: size)
            .overlay {
                if let u = URL(string: url) {
                    AsyncImage(url: u) { phase in
                        if case .success(let img) = phase {
                            img.resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        } else {
                            Color(AppColors.cardHover)
                        }
                    }
                } else {
                    Color(AppColors.cardHover)
                }
            }
            .clipShape(.rect(cornerRadius: AppRadius.md))
            .rotationEffect(.degrees(angle))
            .shadow(color: .black.opacity(0.45), radius: 10, y: 5)
            .opacity(appeared ? 0.92 : 0)
            .scaleEffect(appeared ? 1 : 0.6)
            .offset(y: drift ? -7 : 7)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.72).delay(delay)) {
                    appeared = true
                }
                withAnimation(
                    .easeInOut(duration: Double.random(in: 2.6...3.8))
                        .repeatForever(autoreverses: true)
                        .delay(delay)
                ) {
                    drift = true
                }
            }
    }
}

// MARK: - Shortcut card

/// Grote tegel met cover-achtergrond (of icoon bij geen content) + label.
struct LibraryShortcutCard: View {
    let title: String
    let icon: String
    let covers: [String]

    private var hasCover: Bool { !covers.isEmpty }

    var body: some View {
        Color(AppColors.card)
            .frame(height: 128)
            .frame(maxWidth: .infinity)
            .overlay { coverBackground }
            .overlay {
                if hasCover {
                    LinearGradient(
                        colors: [.black.opacity(0.1), .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .allowsHitTesting(false)
                }
            }
            .overlay(alignment: .center) {
                if !hasCover {
                    Image(systemName: icon)
                        .font(.system(size: 38, weight: .black))
                        .foregroundStyle(AppColors.yellow.opacity(0.55))
                }
            }
            .overlay(alignment: .bottomLeading) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(AppColors.yellow)
                    Text(title)
                        .font(.system(size: AppFontSize.base, weight: .black))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.6), radius: 3)
                }
                .padding(AppSpacing.md)
            }
            .clipShape(.rect(cornerRadius: AppRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .stroke(AppColors.yellow.opacity(hasCover ? 0.0 : 0.25), lineWidth: 1)
            )
    }

    @ViewBuilder
    private var coverBackground: some View {
        if covers.count >= 4 {
            VStack(spacing: 1) {
                HStack(spacing: 1) {
                    coverTile(covers[0])
                    coverTile(covers[1])
                }
                HStack(spacing: 1) {
                    coverTile(covers[2])
                    coverTile(covers[3])
                }
            }
        } else if let first = covers.first {
            coverTile(first)
        }
    }

    private func coverTile(_ urlStr: String) -> some View {
        Color(AppColors.cardHover)
            .overlay {
                if let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        } else {
                            Color(AppColors.cardHover)
                        }
                    }
                } else {
                    Color(AppColors.cardHover)
                }
            }
            .clipped()
    }
}

// MARK: - Recent track card (horizontal strip)

struct RecentTrackCard: View {
    let track: Track

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            TrackThumbnail(
                url: track.thumbnailUrl,
                cornerRadius: AppRadius.md,
                isCurrent: MusicPlayer.shared.currentTrack?.id == track.id,
                isPlaying: MusicPlayer.shared.currentTrack?.id == track.id && MusicPlayer.shared.isPlaying,
                hasVideo: track.videoUrl != nil
            )
            .frame(width: 132, height: 132)

            Text(track.title)
                .font(.system(size: AppFontSize.sm, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
            Text(track.artistName)
                .font(.system(size: AppFontSize.xs, weight: .bold))
                .foregroundStyle(AppColors.yellow)
                .lineLimit(1)
        }
        .frame(width: 132)
    }
}
