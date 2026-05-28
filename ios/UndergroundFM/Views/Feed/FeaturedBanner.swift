//
//  FeaturedBanner.swift
//  UndergroundFM
//

import SwiftUI

struct FeaturedBanner: View {
    let track: Track?
    let isLoading: Bool
    @Bindable var l10n: L10n
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                Color(AppColors.card)
                    .aspectRatio(16.0/9.0, contentMode: .fit)
                    .overlay {
                        if let track = track, let urlStr = track.thumbnailUrl, let u = URL(string: urlStr) {
                            AsyncImage(url: u) { phase in
                                switch phase {
                                case .success(let img):
                                    img.resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .allowsHitTesting(false)
                                default:
                                    placeholder
                                }
                            }
                        } else {
                            placeholder
                        }
                    }
                    .overlay(
                        LinearGradient(
                            colors: [.clear, .clear, AppColors.bg.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .allowsHitTesting(false)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                            .stroke(AppColors.border, lineWidth: 1)
                    )

                // Inhoud onderaan
                if let track = track {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(l10n.t("feed.featured"))
                                .font(.system(size: AppFontSize.xs, weight: .black))
                                .tracking(2)
                                .foregroundStyle(AppColors.yellow)
                            Text(track.title)
                                .font(.system(size: AppFontSize.xl, weight: .black))
                                .foregroundStyle(AppColors.textPrimary)
                                .lineLimit(1)
                            Text(track.artistName)
                                .font(.system(size: AppFontSize.sm, weight: .medium))
                                .foregroundStyle(AppColors.textSecond)
                                .lineLimit(1)
                        }
                        Spacer()
                        playButton
                    }
                    .padding(AppSpacing.lg)
                } else if isLoading {
                    skeletonContent
                        .padding(AppSpacing.lg)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AppSpacing.lg)
    }

    private var playButton: some View {
        ZStack {
            Circle()
                .fill(AppColors.yellow)
                .frame(width: 52, height: 52)
            Image(systemName: "play.fill")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(AppColors.yellowText)
                .offset(x: 2)
        }
    }

    private var placeholder: some View {
        Image(systemName: "waveform")
            .font(.system(size: 48, weight: .bold))
            .foregroundStyle(AppColors.textMuted)
    }

    private var skeletonContent: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4).fill(AppColors.cardHover).frame(width: 80, height: 10)
                RoundedRectangle(cornerRadius: 4).fill(AppColors.cardHover).frame(width: 180, height: 22)
                RoundedRectangle(cornerRadius: 4).fill(AppColors.cardHover).frame(width: 120, height: 12)
            }
            Spacer()
        }
    }
}
