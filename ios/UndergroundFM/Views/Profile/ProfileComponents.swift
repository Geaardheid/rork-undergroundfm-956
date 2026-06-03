//
//  ProfileComponents.swift
//  UndergroundFM
//
//  Herbruikbare bouwstenen voor de profiel- en artiestenpagina's.
//

import SwiftUI

// MARK: - Avatar

struct ProfileAvatar: View {
    let initials: String
    var photoUrl: String? = nil
    var size: CGFloat = 96
    var onTap: (() -> Void)? = nil

    var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) { avatar }
                    .buttonStyle(PressableScaleStyle())
            } else {
                avatar
            }
        }
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(AppColors.card)
                .overlay(Circle().stroke(AppColors.yellow, lineWidth: 2))
                .overlay {
                    if let photoUrl, let url = URL(string: photoUrl) {
                        AsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                initialsText
                            }
                        }
                    } else {
                        initialsText
                    }
                }
                .clipShape(Circle())
            if onTap != nil {
                Circle()
                    .fill(AppColors.yellow)
                    .frame(width: size * 0.3, height: size * 0.3)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: size * 0.13, weight: .black))
                            .foregroundStyle(AppColors.yellowText)
                    )
                    .overlay(Circle().stroke(AppColors.bg, lineWidth: 3))
                    .offset(x: size * 0.32, y: size * 0.32)
            }
        }
        .frame(width: size, height: size)
    }

    private var initialsText: some View {
        Text(initials)
            .font(.system(size: size * 0.38, weight: .black, design: .rounded))
            .foregroundStyle(AppColors.yellow)
    }
}

// MARK: - Stat card + row

struct StatCard: View {
    let value: String
    let label: String
    var accent: Bool = false
    var isLoading: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            if isLoading {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.cardHover)
                    .frame(width: 40, height: 22)
            } else {
                Text(value)
                    .font(.system(size: AppFontSize.xl, weight: .black, design: .rounded))
                    .foregroundStyle(accent ? AppColors.yellow : AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Text(label)
                .font(.system(size: AppFontSize.xs, weight: .bold))
                .foregroundStyle(AppColors.textSecond)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 28, alignment: .top)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .padding(.horizontal, AppSpacing.sm)
        .background(AppColors.card)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .clipShape(.rect(cornerRadius: AppRadius.md))
    }
}

struct StatsRow: View {
    let stats: ArtistMonthStats
    let isLoading: Bool
    @Bindable var l10n: L10n

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            StatCard(
                value: "\(stats.supporters)",
                label: l10n.t("stats.supporters"),
                isLoading: isLoading
            )
            StatCard(
                value: formatPoints(stats.scenePoints),
                label: l10n.t("stats.points"),
                accent: true,
                isLoading: isLoading
            )
            StatCard(
                value: stats.ranking > 0 ? "#\(stats.ranking)" : "—",
                label: l10n.t("stats.ranking"),
                isLoading: isLoading
            )
        }
    }

    private func formatPoints(_ v: Double) -> String {
        if v >= 1000 {
            return String(format: "%.1fk", v / 1000)
        }
        return String(format: "%.0f", v)
    }
}

// MARK: - Section header

struct ProfileSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: AppFontSize.xs, weight: .black))
            .tracking(2)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Badges

struct FoundingBadge: View {
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .font(.system(size: 12, weight: .black))
            Text(label)
                .font(.system(size: AppFontSize.sm, weight: .black))
        }
        .foregroundStyle(AppColors.yellowText)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 8)
        .background(AppColors.yellow)
        .clipShape(Capsule())
    }
}

struct SubscriptionBadge: View {
    let isActive: Bool
    let activeLabel: String
    let inactiveLabel: String

    var body: some View {
        let color = isActive ? AppColors.success : AppColors.error
        return HStack(spacing: 6) {
            Image(systemName: isActive ? "checkmark.seal.fill" : "xmark.seal.fill")
                .font(.system(size: 12, weight: .bold))
            Text(isActive ? activeLabel : inactiveLabel)
                .font(.system(size: AppFontSize.sm, weight: .bold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 8)
        .background(color.opacity(0.12))
        .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
        .clipShape(Capsule())
    }
}

// MARK: - Genre tags

struct GenreTagsRow: View {
    let tags: [String]

    var body: some View {
        FlowChips(
            items: tags.map { GenreChip(id: $0, label: displayName($0)) },
            isSelected: { _ in false },
            onTap: { _ in }
        )
        .allowsHitTesting(false)
    }

    private func displayName(_ raw: String) -> String {
        switch raw.lowercased() {
        case "rb", "r&b": return "R&B"
        default: return raw.prefix(1).uppercased() + raw.dropFirst()
        }
    }
}
