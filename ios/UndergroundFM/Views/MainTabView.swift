//
//  MainTabView.swift
//  UndergroundFM
//
//  Custom liquid-glass tab bar (5 tabs, upload alleen voor artiesten).
//  Includes persistent mini player above the tab bar.
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
    @State private var showFullPlayer: Bool = false
    @State private var artistRoute: ArtistRoute?
    @Namespace private var tabIndicator

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
                case .upload:   UploadTrackView(l10n: l10n)
                case .library:  LibraryView(l10n: l10n)
                case .profile:  ProfileView(l10n: l10n)
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomArea
            }
        }
        .sheet(isPresented: $showFullPlayer) {
            PlayerView(l10n: l10n, onTapArtist: { route in
                showFullPlayer = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    artistRoute = route
                }
            })
            .presentationDetents([.large])
            .presentationBackground(.black)
        }
        .sheet(item: $artistRoute) { route in
            NavigationStack {
                ArtistProfileView(route: route, l10n: l10n)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                artistRoute = nil
                            } label: {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(AppColors.textPrimary)
                            }
                        }
                    }
            }
            .presentationBackground(AppColors.bg)
        }
    }

    // MARK: - Bottom area (mini player + tab bar)

    private var bottomArea: some View {
        VStack(spacing: 0) {
            MiniPlayerView(
                player: MusicPlayer.shared,
                showFullPlayer: $showFullPlayer
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: MusicPlayer.shared.hasTrack)

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
                    label: l10n.t(tab.labelKey),
                    namespace: tabIndicator
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selected = tab
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.5), radius: 16, x: 0, y: 6)
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.sm)
    }
}

private struct TabButton: View {
    let tab: AppTab
    let isSelected: Bool
    let label: String
    let namespace: Namespace.ID
    let action: () -> Void

    private static let inactiveColor = Color(hex: 0x555555)

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22, weight: .semibold))
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .lineLimit(1)

                // Active-tab indicator dot
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(AppColors.yellow)
                            .frame(width: 5, height: 5)
                            .matchedGeometryEffect(id: "tabDot", in: namespace)
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 5, height: 5)
                    }
                }
            }
            .foregroundStyle(isSelected ? AppColors.yellow : Self.inactiveColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
