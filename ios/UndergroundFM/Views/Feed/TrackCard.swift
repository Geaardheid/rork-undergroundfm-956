//
//  TrackCard.swift
//  UndergroundFM
//

import SwiftUI

struct TrackCard: View {
    let track: Track
    var highlighted: Bool = false
    var width: CGFloat = 150
    var onTap: () -> Void = {}

    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                TrackThumbnail(url: track.thumbnailUrl, highlighted: highlighted)
                    .frame(width: width)

                Text(track.title)
                    .font(.system(size: AppFontSize.base, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)

                Text(track.artistName)
                    .font(.system(size: AppFontSize.sm, weight: .medium))
                    .foregroundStyle(AppColors.textSecond)
                    .lineLimit(1)
            }
            .frame(width: width, alignment: .leading)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

/// Skeleton variant tijdens laden.
struct TrackCardSkeleton: View {
    var width: CGFloat = 150
    @State private var pulse: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppColors.card)
                .aspectRatio(16.0/9.0, contentMode: .fit)
                .frame(width: width)
                .opacity(pulse ? 0.6 : 1.0)

            RoundedRectangle(cornerRadius: 4)
                .fill(AppColors.card)
                .frame(width: width * 0.8, height: 12)
                .opacity(pulse ? 0.6 : 1.0)

            RoundedRectangle(cornerRadius: 4)
                .fill(AppColors.card)
                .frame(width: width * 0.5, height: 10)
                .opacity(pulse ? 0.6 : 1.0)
        }
        .frame(width: width, alignment: .leading)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
