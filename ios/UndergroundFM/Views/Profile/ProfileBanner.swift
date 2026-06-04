//
//  ProfileBanner.swift
//  UndergroundFM
//
//  Volle-breedte profielbanner met geüploade afbeelding of auto-gegenereerd
//  gradient (afgeleid uit de artiest-initialen). Vervaagt onderaan naar
//  AppColors.bg en draagt een paar zwevende muzieknoten voor sfeer.
//

import SwiftUI

/// Deterministische kleur op basis van een seed (bv. initialen).
enum ProfileColor {
    static func color(for seed: String) -> Color {
        var hash = 5381
        for scalar in seed.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ Int(scalar.value)
        }
        let hue = Double(abs(hash) % 360) / 360.0
        return Color(hue: hue, saturation: 0.62, brightness: 0.52)
    }
}

struct ProfileBanner: View {
    let bannerUrl: String?
    let seed: String
    var height: CGFloat = 180

    var body: some View {
        let base = ProfileColor.color(for: seed)
        ZStack {
            if let bannerUrl, let url = URL(string: bannerUrl) {
                Color(AppColors.card)
                    .overlay {
                        AsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                gradient(base)
                            }
                        }
                        .allowsHitTesting(false)
                    }
            } else {
                gradient(base)
            }

            FloatingNotes()

            // Vervaag onderaan naar de profielachtergrond zodat hij naadloos overloopt.
            LinearGradient(
                colors: [.clear, .clear, AppColors.bg.opacity(0.65), AppColors.bg],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
    }

    private func gradient(_ base: Color) -> some View {
        LinearGradient(
            colors: [base, base.opacity(0.55), AppColors.bg],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/// Subtiele zwevende muzieknoten/waveforms in geel, licht geroteerd.
private struct FloatingNotes: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                FloatingNote(symbol: "music.note", size: 46, opacity: 0.16, rotation: -18, delay: 0)
                    .position(x: geo.size.width * 0.16, y: geo.size.height * 0.32)
                FloatingNote(symbol: "waveform", size: 64, opacity: 0.13, rotation: 10, delay: 0.6)
                    .position(x: geo.size.width * 0.83, y: geo.size.height * 0.26)
                FloatingNote(symbol: "music.note", size: 32, opacity: 0.10, rotation: 22, delay: 1.1)
                    .position(x: geo.size.width * 0.6, y: geo.size.height * 0.58)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct FloatingNote: View {
    let symbol: String
    let size: CGFloat
    let opacity: Double
    let rotation: Double
    let delay: Double

    @State private var bob: Bool = false

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size, weight: .black))
            .foregroundStyle(AppColors.yellow.opacity(opacity))
            .rotationEffect(.degrees(rotation))
            .offset(y: bob ? -6 : 6)
            .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true).delay(delay), value: bob)
            .onAppear { bob = true }
    }
}
