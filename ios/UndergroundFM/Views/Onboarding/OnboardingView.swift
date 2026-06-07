//
//  OnboardingView.swift
//  UndergroundFM
//
//  First-launch welcome flow. Shown once, then never again.
//  Cinematic, fully code-generated visuals in the style of undergroundfm.nl.
//

import SwiftUI

struct OnboardingView: View {
    @Bindable var l10n: L10n
    /// Called when the user chooses "Inloggen" — finishes onboarding and goes to login.
    let onLogin: () -> Void
    /// Called when the user chooses "Registreren" — finishes onboarding and opens register.
    /// Bool = whether the artist role was selected on the role slide.
    let onRegister: (Bool) -> Void

    @State private var page: Int = 0
    @State private var isArtist: Bool = false

    private let lastPage: Int = 4

    var body: some View {
        ZStack {
            // Cinematic background reacts to the active slide.
            CinematicBackground(stop: page)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    slide1.tag(0)
                    slide2.tag(1)
                    slide3.tag(2)
                    slide4.tag(3)
                    slide5.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: page)

                bottomBar
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.lg)
            }
        }
    }

    // MARK: - Bottom bar (dots + Volgende)

    private var bottomBar: some View {
        ZStack {
            dots
            HStack {
                Spacer()
                if page < lastPage {
                    nextButton
                }
            }
        }
        .frame(height: 52)
    }

    private var dots: some View {
        HStack(spacing: 8) {
            ForEach(0...lastPage, id: \.self) { i in
                Capsule()
                    .fill(i == page ? AppColors.yellow : AppColors.border)
                    .frame(width: i == page ? 22 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: page)
            }
        }
    }

    private var nextButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.35)) {
                page = min(page + 1, lastPage)
            }
        } label: {
            HStack(spacing: 6) {
                Text(l10n.t("onb.next"))
                    .font(.system(size: AppFontSize.base, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(AppColors.yellowText)
            .padding(.horizontal, AppSpacing.lg)
            .frame(height: 48)
            .background(AppColors.yellow)
            .clipShape(Capsule())
            .shadow(color: AppColors.yellow.opacity(0.35), radius: 16, y: 4)
        }
        .buttonStyle(PressableScaleStyle())
    }

    // MARK: - Slide 1 — Alleen Underground

    private var slide1: some View {
        SlideContainer(index: 0, activePage: page) { rise in
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Spacer()

                VStack(alignment: .leading, spacing: -6) {
                    Text(l10n.t("onb.s1.line1"))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(l10n.t("onb.s1.line2"))
                        .foregroundStyle(AppColors.yellow)
                }
                .font(.system(size: 52, weight: .black, design: .rounded))
                .tracking(-1)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .shadow(color: .black.opacity(0.6), radius: 12, y: 6)
                .modifier(rise(0))

                Text(l10n.t("onb.s1.subtitle"))
                    .font(.system(size: AppFontSize.md, weight: .medium))
                    .foregroundStyle(AppColors.textSecond)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, AppSpacing.xs)
                    .modifier(rise(1))

                statBadges
                    .padding(.top, AppSpacing.md)
                    .modifier(rise(2))

                Spacer()
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.xl)
        }
    }

    private var statBadges: some View {
        let items = [
            l10n.t("onb.s1.stat1"),
            l10n.t("onb.s1.stat2"),
            l10n.t("onb.s1.stat3"),
            l10n.t("onb.s1.stat4")
        ]
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.system(size: AppFontSize.sm, weight: .bold))
                        .foregroundStyle(AppColors.yellow)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColors.yellow.opacity(0.12))
                        .overlay(
                            Capsule().stroke(AppColors.yellow.opacity(0.5), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Slide 2 — Wat het is

    private var slide2: some View {
        SlideContainer(index: 1, activePage: page) { rise in
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Spacer()

                Text(l10n.t("onb.s2b.title"))
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .tracking(-1)
                    .foregroundStyle(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .shadow(color: .black.opacity(0.6), radius: 12, y: 6)
                    .modifier(rise(0))

                Rectangle()
                    .fill(AppColors.yellow)
                    .frame(width: 56, height: 4)
                    .clipShape(Capsule())
                    .modifier(rise(1))

                Text(l10n.t("onb.s2b.body"))
                    .font(.system(size: AppFontSize.lg, weight: .medium))
                    .foregroundStyle(AppColors.textSecond)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
                    .modifier(rise(2))

                Spacer()
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.xl)
        }
    }

    // MARK: - Slide 3 — Eerlijk betaald

    private var slide3: some View {
        SlideContainer(index: 2, activePage: page) { rise in
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Spacer()

                Text(l10n.t("onb.s2c.title"))
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .tracking(-1)
                    .foregroundStyle(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .shadow(color: .black.opacity(0.6), radius: 12, y: 6)
                    .modifier(rise(0))

                Text(l10n.t("onb.s2c.body"))
                    .font(.system(size: AppFontSize.lg, weight: .medium))
                    .foregroundStyle(AppColors.textSecond)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
                    .modifier(rise(1))

                VStack(spacing: AppSpacing.md) {
                    figureRow(value: l10n.t("onb.s1.stat1"), index: 0)
                    figureRow(value: l10n.t("onb.s1.stat2"), index: 1)
                    figureRow(value: l10n.t("onb.s1.stat3"), index: 2)
                }
                .padding(.top, AppSpacing.sm)
                .modifier(rise(2))

                Spacer()
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.xl)
        }
    }

    private func figureRow(value: String, index: Int) -> some View {
        HStack(spacing: AppSpacing.md) {
            Text("0\(index + 1)")
                .font(.system(size: AppFontSize.sm, weight: .black, design: .monospaced))
                .foregroundStyle(AppColors.yellow.opacity(0.7))
            Text(value)
                .font(.system(size: AppFontSize.xl, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
        }
        .padding(.vertical, AppSpacing.md)
        .padding(.horizontal, AppSpacing.lg)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.yellow.opacity(0.18), lineWidth: 1)
        )
        .clipShape(.rect(cornerRadius: AppRadius.md))
    }

    // MARK: - Slide 4 — Kies je rol

    private var slide4: some View {
        SlideContainer(index: 3, activePage: page) { rise in
            VStack(spacing: AppSpacing.xl) {
                Spacer()

                Text(l10n.t("onb.s2.title"))
                    .font(.system(size: AppFontSize.xxl, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                    .shadow(color: .black.opacity(0.6), radius: 10, y: 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .modifier(rise(0))

                VStack(spacing: AppSpacing.lg) {
                    roleCard(
                        emoji: "🎧",
                        title: l10n.t("role.fan"),
                        hint: l10n.t("onb.s2.fanHint"),
                        selected: !isArtist
                    ) { isArtist = false }
                    .modifier(rise(1))

                    roleCard(
                        emoji: "🎤",
                        title: l10n.t("role.artist"),
                        hint: l10n.t("onb.s2.artistHint"),
                        selected: isArtist
                    ) { isArtist = true }
                    .modifier(rise(2))
                }

                Spacer()
                Spacer()
            }
            .padding(.horizontal, AppSpacing.xl)
        }
    }

    private func roleCard(emoji: String, title: String, hint: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Text(emoji)
                    .font(.system(size: 36))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: AppFontSize.lg, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(hint)
                        .font(.system(size: AppFontSize.xs, weight: .medium))
                        .foregroundStyle(AppColors.textSecond)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(selected ? AppColors.yellow : AppColors.border)
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? AppColors.yellow.opacity(0.10) : AppColors.card.opacity(0.85))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(selected ? AppColors.yellow : AppColors.border, lineWidth: selected ? 2 : 1)
            )
            .clipShape(.rect(cornerRadius: AppRadius.lg))
        }
        .buttonStyle(PressableScaleStyle())
    }

    // MARK: - Slide 5 — Wees er bij

    private var slide5: some View {
        SlideContainer(index: 4, activePage: page) { rise in
            VStack(spacing: AppSpacing.lg) {
                Spacer()

                Text(l10n.t("onb.s3.badge"))
                    .font(.system(size: AppFontSize.xs, weight: .black))
                    .tracking(1)
                    .foregroundStyle(AppColors.yellowText)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, 6)
                    .background(AppColors.yellow)
                    .clipShape(Capsule())
                    .modifier(rise(0))

                Text(l10n.t("onb.s3.title"))
                    .font(.system(size: AppFontSize.hero, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.6), radius: 12, y: 6)
                    .modifier(rise(1))

                Text(l10n.t("onb.s3.subtitle"))
                    .font(.system(size: AppFontSize.md, weight: .medium))
                    .foregroundStyle(AppColors.textSecond)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, AppSpacing.md)
                    .modifier(rise(2))

                Spacer()

                PrimaryButton(title: l10n.t("auth.register")) {
                    onRegister(isArtist)
                }
                .modifier(rise(3))

                Button {
                    onLogin()
                } label: {
                    Text("\(l10n.t("auth.hasAccount")) \(l10n.t("auth.login"))")
                        .font(.system(size: AppFontSize.base, weight: .semibold))
                        .foregroundStyle(AppColors.textSecond)
                }
                .padding(.top, AppSpacing.xs)
                .modifier(rise(4))

                Spacer()
            }
            .padding(.horizontal, AppSpacing.xl)
        }
    }
}

// MARK: - Slide container with staggered "rise" animation

/// Wraps a slide's content and provides a `rise(_:)` modifier factory that fades +
/// moves each element up when this slide becomes the active page.
private struct SlideContainer<Content: View>: View {
    let index: Int
    let activePage: Int
    @ViewBuilder let content: (_ rise: @escaping (Int) -> RiseEffect) -> Content

    private var isActive: Bool { index == activePage }

    var body: some View {
        content { order in
            RiseEffect(isActive: isActive, order: order)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Staggered fade + upward-move entrance. `order` controls the delay so elements
/// cascade into place.
private struct RiseEffect: ViewModifier {
    let isActive: Bool
    let order: Int

    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 1 : 0)
            .offset(y: isActive ? 0 : 20)
            .animation(
                .easeOut(duration: 0.75).delay(isActive ? 0.12 + Double(order) * 0.10 : 0),
                value: isActive
            )
    }
}

// MARK: - Cinematic background (fully code-generated)

/// Code-drawn cinematic backdrop: deep black, a breathing yellow glow, a still
/// film-grain layer, a vignette, and a faint decorative "U" spray motif.
/// Android-portable: no image files, pure SwiftUI primitives.
private struct CinematicBackground: View {
    let stop: Int

    @State private var breathe: Bool = false

    /// Per-slide glow anchor + tint so each screen feels distinct.
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
private struct GrainOverlay: View {
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
private struct SeededGenerator: RandomNumberGenerator {
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
