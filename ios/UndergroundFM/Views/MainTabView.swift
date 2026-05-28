//
//  MainTabView.swift
//  UndergroundFM
//
//  Custom liquid-glass tab bar (5 tabs, upload alleen voor artiesten).
//

import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home, discover, upload, library, profile
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home:     return "house.fill"
        case .discover: return "sparkles"
        case .upload:   return "plus.circle.fill"
        case .library:  return "music.note.list"
        case .profile:  return "person.fill"
        }
    }

    var labelKey: String {
        switch self {
        case .home:     return "tab.home"
        case .discover: return "tab.discover"
        case .upload:   return "tab.upload"
        case .library:  return "tab.library"
        case .profile:  return "tab.profile"
        }
    }
}

struct MainTabView: View {
    @Environment(AuthStore.self) private var auth
    @Bindable var l10n: L10n
    @State private var selected: AppTab = .home

    private var visibleTabs: [AppTab] {
        let isArtist = auth.currentUser?.role == .artist
        return AppTab.allCases.filter { $0 != .upload || isArtist }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.bg.ignoresSafeArea()

            Group {
                switch selected {
                case .home:     HomeFeedView(l10n: l10n)
                case .discover: ComingSoonView(l10n: l10n, titleKey: "tab.discover", icon: "sparkles")
                case .upload:   ComingSoonView(l10n: l10n, titleKey: "tab.upload",   icon: "plus.circle.fill")
                case .library:  ComingSoonView(l10n: l10n, titleKey: "tab.library",  icon: "music.note.list")
                case .profile:  ProfileView(l10n: l10n)
                }
            }

            tabBar
        }
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(visibleTabs) { tab in
                TabButton(
                    tab: tab,
                    isSelected: selected == tab,
                    label: l10n.t(tab.labelKey)
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selected = tab
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 10)
        .background(tabBarBackground)
        .overlay(
            Capsule().stroke(AppColors.border, lineWidth: 1)
        )
        .clipShape(Capsule())
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.sm)
    }

    @ViewBuilder
    private var tabBarBackground: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(.clear)
                .glassEffect(.regular.tint(AppColors.bg.opacity(0.6)), in: Capsule())
        } else {
            Capsule()
                .fill(AppColors.card.opacity(0.85))
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
}

private struct TabButton: View {
    let tab: AppTab
    let isSelected: Bool
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: .bold))
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? AppColors.yellow : AppColors.textSecond)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                Group {
                    if isSelected {
                        Capsule().fill(AppColors.yellow.opacity(0.12))
                    } else {
                        Color.clear
                    }
                }
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
