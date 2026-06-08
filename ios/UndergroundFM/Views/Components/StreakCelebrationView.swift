//
//  StreakCelebrationView.swift
//  UndergroundFM
//
//  Duolingo-style daily-streak celebration. Full-screen, on-brand fire theme.
//  Code-drawn flame + sparkles (no image files); reuses the LogoU asset for the
//  "U" pop. Android-portable in spirit — only the haptics/share are iOS-specific.
//

import SwiftUI
import UIKit

struct StreakCelebrationView: View {
    let celebration: StreakCelebration
    @Bindable var l10n: L10n
    let onContinue: () -> Void

    // Staggered animation flags.
    @State private var bgIn: Bool = false
    @State private var burstIn: Bool = false
    @State private var logoIn: Bool = false
    @State private var sparklesOut: Bool = false
    @State private var showNewNumber: Bool = false
    @State private var litDays: Int = 0
    @State private var buttonsIn: Bool = false
    @State private var flamePulse: Bool = false

    private static let sparkles: [Sparkle] = (0..<14).map { i in
        Sparkle(
            angle: Double(i) / 14.0 * 2 * .pi + Double.random(in: -0.2...0.2),
            distance: Double.random(in: 90...170),
            size: Double.random(in: 5...11),
            isOrange: i % 2 == 0
        )
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: AppSpacing.xl) {
                Spacer(minLength: 0)

                burst
                    .padding(.bottom, AppSpacing.sm)

                streakNumber

                weekCalendar
                    .padding(.top, AppSpacing.sm)

                Spacer(minLength: 0)

                buttons
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.xxxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { runSequence() }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            AppColors.bg

            // Fiery glow rising from below the burst.
            RadialGradient(
                colors: [
                    AppColors.yellow.opacity(0.45),
                    Color(hex: 0xFF6A00).opacity(0.30),
                    Color(hex: 0xFF6A00).opacity(0.0)
                ],
                center: UnitPoint(x: 0.5, y: 0.40),
                startRadius: 0,
                endRadius: bgIn ? 520 : 320
            )
            .opacity(bgIn ? 1 : 0)

            // Warm vertical wash for depth.
            LinearGradient(
                colors: [
                    Color(hex: 0xFF8A00).opacity(0.18),
                    .clear,
                    AppColors.bg.opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(bgIn ? 1 : 0)

            GrainOverlay()
                .opacity(0.06)
                .blendMode(.overlay)

            RadialGradient(
                colors: [.clear, .black.opacity(0.6)],
                center: .center,
                startRadius: 180,
                endRadius: 680
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Burst (flame + logo + sparkles)

    private var burst: some View {
        ZStack {
            // Outer glow halo.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppColors.yellow.opacity(0.55), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 130
                    )
                )
                .frame(width: 260, height: 260)
                .scaleEffect(flamePulse ? 1.08 : 0.9)
                .opacity(burstIn ? 1 : 0)
                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: flamePulse)

            // Sparkle particles flying out.
            ForEach(Self.sparkles) { s in
                Circle()
                    .fill(s.isOrange ? Color(hex: 0xFF7A00) : AppColors.yellow)
                    .frame(width: s.size, height: s.size)
                    .offset(
                        x: sparklesOut ? cos(s.angle) * s.distance : 0,
                        y: sparklesOut ? sin(s.angle) * s.distance : 0
                    )
                    .opacity(sparklesOut ? 0 : 1)
                    .animation(.easeOut(duration: 1.0), value: sparklesOut)
            }

            // Code-drawn flame.
            Image(systemName: "flame.fill")
                .font(.system(size: 120))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.yellow, Color(hex: 0xFF7A00), Color(hex: 0xFF3B00)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color(hex: 0xFF6A00).opacity(0.8), radius: 24)
                .scaleEffect(burstIn ? (flamePulse ? 1.05 : 1.0) : 0.2)
                .opacity(burstIn ? 1 : 0)
                .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: flamePulse)

            // LogoU pops in over the flame.
            Image("LogoU")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .shadow(color: .black.opacity(0.5), radius: 8)
                .scaleEffect(logoIn ? 1 : 0.1)
                .opacity(logoIn ? 1 : 0)
                .offset(y: 6)
        }
        .frame(height: 260)
    }

    // MARK: - Streak number

    private var streakNumber: some View {
        VStack(spacing: AppSpacing.xs) {
            ZStack {
                Text("\(celebration.previousStreak)")
                    .opacity(showNewNumber ? 0 : 1)
                    .scaleEffect(showNewNumber ? 0.6 : 1)
                Text("\(celebration.newStreak)")
                    .opacity(showNewNumber ? 1 : 0)
                    .scaleEffect(showNewNumber ? 1 : 0.6)
            }
            .font(.system(size: 96, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: AppColors.yellow.opacity(0.5), radius: 18)
            .animation(.spring(response: 0.45, dampingFraction: 0.55), value: showNewNumber)

            Text(l10n.t("streak.daysInARow"))
                .font(.system(size: AppFontSize.md, weight: .bold))
                .foregroundStyle(AppColors.yellow)
                .textCase(.uppercase)
                .kerning(1.5)
                .opacity(burstIn ? 1 : 0)
        }
    }

    // MARK: - Week calendar

    private var weekCalendar: some View {
        let labels = l10n.t("streak.weekdays").split(separator: ",").map(String.init)
        return HStack(spacing: AppSpacing.sm) {
            ForEach(Array(celebration.weekProgress.enumerated()), id: \.offset) { index, achieved in
                let lit = achieved && index < litDays
                VStack(spacing: 6) {
                    Text(index < labels.count ? labels[index] : "")
                        .font(.system(size: AppFontSize.xs, weight: .bold))
                        .foregroundStyle(AppColors.textSecond)

                    ZStack {
                        Circle()
                            .fill(lit ? AppColors.yellow : AppColors.card)
                            .overlay(
                                Circle().stroke(
                                    lit ? Color.clear : AppColors.border,
                                    lineWidth: 1.5
                                )
                            )
                        if lit {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundStyle(AppColors.yellowText)
                        }
                    }
                    .frame(width: 34, height: 34)
                    .scaleEffect(lit ? 1 : 0.92)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: lit)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Buttons

    private var buttons: some View {
        VStack(spacing: AppSpacing.md) {
            Button {
                HapticManager.medium()
                presentShareSheet()
            } label: {
                Text(l10n.t("streak.share"))
                    .font(.system(size: AppFontSize.md, weight: .heavy))
                    .kerning(1)
                    .foregroundStyle(AppColors.yellowText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
                    .background(Color.white)
                    .clipShape(.rect(cornerRadius: AppRadius.lg))
            }
            .buttonStyle(.plain)

            Button {
                HapticManager.light()
                onContinue()
            } label: {
                Text(l10n.t("streak.continue"))
                    .font(.system(size: AppFontSize.md, weight: .heavy))
                    .kerning(1)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .stroke(AppColors.borderLight, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
        }
        .opacity(buttonsIn ? 1 : 0)
        .offset(y: buttonsIn ? 0 : 16)
        .animation(.easeOut(duration: 0.5), value: buttonsIn)
    }

    // MARK: - Sequence

    private func runSequence() {
        withAnimation(.easeOut(duration: 0.6)) { bgIn = true }

        // Burst + heavy haptic.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { burstIn = true }
            HapticManager.heavy()
            flamePulse = true
            withAnimation(.easeOut(duration: 1.0)) { sparklesOut = true }
        }

        // Logo pop.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { logoIn = true }
        }

        // Number flip + medium haptic.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showNewNumber = true
            HapticManager.medium()
        }

        // Staggered day check-ins.
        let achievedCount = celebration.weekProgress.filter { $0 }.count
        for day in 1...max(achievedCount, 1) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4 + Double(day) * 0.1) {
                guard day <= achievedCount else { return }
                litDays = day
                HapticManager.light()
            }
        }

        // Buttons.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4 + Double(achievedCount) * 0.1 + 0.2) {
            buttonsIn = true
        }
    }

    // MARK: - Share

    private var shareText: String {
        String(format: l10n.t("streak.shareText"), celebration.newStreak)
    }

    private func presentShareSheet() {
        let message = shareText
        var items: [Any] = [message]
        if let link = URL(string: "https://undergroundfm.nl") {
            items.append(link)
        }
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
        var presenter = root
        while let p = presenter.presentedViewController { presenter = p }
        if let pop = vc.popoverPresentationController {
            pop.sourceView = presenter.view
            pop.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
        presenter.present(vc, animated: true)
    }
}

/// A single sparkle particle for the burst.
private struct Sparkle: Identifiable {
    let id = UUID()
    let angle: Double
    let distance: Double
    let size: Double
    let isOrange: Bool
}
