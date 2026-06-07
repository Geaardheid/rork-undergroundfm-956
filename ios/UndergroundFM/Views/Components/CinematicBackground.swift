//
//  CinematicBackground.swift
//  UndergroundFM
//
//  Code-drawn cinematic backdrop in the style of undergroundfm.nl.
//  Deep black, a breathing yellow glow, a still film-grain layer, a vignette,
//  and a faint decorative "U" spray motif.
//  Android-portable: no image files, pure SwiftUI primitives.
//

import SwiftUI

/// Code-drawn cinematic backdrop shared across onboarding, splash and login.
struct CinematicBackground: View {
    /// Which "stop" the background is showing — changes the glow anchor + tint so
    /// each screen feels distinct. Defaults to 0.
    var stop: Int = 0

    @State private var breathe: Bool = false

    /// Per-stop glow anchor so each screen feels distinct.
    private var glowPoint: UnitPoint {
        switch stop {
        case 0: return UnitPoint(x: 0.30, y: 0.12)
        case 1: return UnitPoint(x: 0.78, y: 0.16)
        case 2: return UnitPoint(x: 0.22, y: 0.20)
        case 3: return UnitPoint(x: 0.80, y: 0.10)
        default: return UnitPoint(x: 0.50, y: 0.06)
        }
    }

    private var glowOpacity: Double {
        switch stop {
        case 2: return 0.12
        case 4: return 0.11
        default: return 0.10
        }
    }

    var body: some View {
        ZStack {
            AppColors.bg

            // Breathing radial yellow glow from the top.
            RadialGradient(
                colors: [
                    AppColors.yellow.opacity(glowOpacity),
                    AppColors.yellow.opacity(glowOpacity * 0.35),
                    .clear
                ],
                center: glowPoint,
                startRadius: 0,
                endRadius: breathe ? 560 : 440
            )
            .opacity(breathe ? 1.0 : 0.65)
            .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: breathe)
            .animation(.easeInOut(duration: 0.8), value: stop)

            // Decorative oversized "U" spray motif, low and rotated.
            Text("U")
                .font(.system(size: 460, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.035))
                .rotationEffect(.degrees(-12))
                .offset(x: 90, y: 230)
                .blur(radius: 1)

            // Still film-grain texture.
            GrainOverlay()
                .opacity(0.06)
                .blendMode(.overlay)

            // Vignette: dark edges brightening toward centre.
            RadialGradient(
                colors: [.clear, .black.opacity(0.55)],
                center: .center,
                startRadius: 160,
                endRadius: 640
            )
        }
        .onAppear { breathe = true }
    }
}

/// A static, procedurally-drawn grain/noise layer. Rendered once via Canvas with a
/// seeded RNG so it doesn't shimmer (calm + battery-friendly).
struct GrainOverlay: View {
    var body: some View {
        Canvas { context, size in
            var rng = SeededGenerator(seed: 0x4D5F4842)
            let count = Int((size.width * size.height) / 900)
            for _ in 0..<count {
                let x = Double.random(in: 0...size.width, using: &rng)
                let y = Double.random(in: 0...size.height, using: &rng)
                let s = Double.random(in: 0.5...1.4, using: &rng)
                let bright = Double.random(in: 0.25...1.0, using: &rng)
                let rect = CGRect(x: x, y: y, width: s, height: s)
                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(bright)))
            }
        }
        .drawingGroup()
    }
}

/// Deterministic RNG so the grain pattern is identical every render (no shimmer).
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed != 0 ? seed : 0x9E3779B97F4A7C15
    }

    mutating func next() -> UInt64 {
        // SplitMix64
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
