//
//  TrackThumbnail.swift
//  UndergroundFM
//

import SwiftUI

/// 16:9 thumbnail met fallback (gele highlight optie zoals in mockup).
struct TrackThumbnail: View {
    let url: String?
    var highlighted: Bool = false
    var cornerRadius: CGFloat = AppRadius.md

    var body: some View {
        Color(highlighted ? AppColors.yellow : AppColors.card)
            .aspectRatio(16.0/9.0, contentMode: .fit)
            .overlay {
                if let urlStr = url, let u = URL(string: urlStr) {
                    AsyncImage(url: u) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        default:
                            placeholderIcon
                        }
                    }
                } else {
                    placeholderIcon
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(highlighted ? AppColors.yellow : AppColors.border, lineWidth: 1)
            )
    }

    private var placeholderIcon: some View {
        Image(systemName: "music.note")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(highlighted ? AppColors.yellowText.opacity(0.5) : AppColors.textMuted)
    }
}
