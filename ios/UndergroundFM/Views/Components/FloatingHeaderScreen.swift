//
//  FloatingHeaderScreen.swift
//  UndergroundFM
//
//  Hide-on-scroll header scaffold (YouTube Music style).
//  Content extends behind the Dynamic Island/camera (.ignoresSafeArea top) and a
//  fully transparent header floats over it. Scrolling down slides the header up
//  and away; scrolling back up brings it back. No solid background bar.
//

import SwiftUI

struct FloatingHeaderScreen<HeaderContent: View, ScrollBody: View>: View {
    @ViewBuilder var header: () -> HeaderContent
    var onRefresh: (() async -> Void)?
    @ViewBuilder var content: () -> ScrollBody

    @State private var headerVisible: Bool = true
    @State private var lastOffset: CGFloat = 0

    /// Ruimte die de header onder de safe-area inneemt (logo/iconen + padding).
    private let headerReserve: CGFloat = 56

    init(
        @ViewBuilder header: @escaping () -> HeaderContent,
        onRefresh: (() async -> Void)? = nil,
        @ViewBuilder content: @escaping () -> ScrollBody
    ) {
        self.header = header
        self.onRefresh = onRefresh
        self.content = content
    }

    var body: some View {
        GeometryReader { geo in
            let topInset = geo.safeAreaInsets.top
            ZStack(alignment: .top) {
                AppColors.bg.ignoresSafeArea()

                scroll(topInset: topInset)

                header()
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, topInset)
                    .offset(y: headerVisible ? 0 : -(topInset + headerReserve + 40))
                    .opacity(headerVisible ? 1 : 0)
                    .animation(.easeInOut(duration: 0.28), value: headerVisible)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all, edges: .top)
        }
    }

    @ViewBuilder
    private func scroll(topInset: CGFloat) -> some View {
        let view = ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Color.clear.frame(height: topInset + headerReserve)
                content()
            }
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { _, newValue in
            updateVisibility(newValue)
        }

        if let onRefresh {
            view
                .refreshable { await onRefresh() }
                .tint(AppColors.yellow)
        } else {
            view
        }
    }

    /// Bepaalt zichtbaarheid op basis van scrollrichting i.p.v. een vaste drempel.
    private func updateVisibility(_ offset: CGFloat) {
        if offset <= 0 {
            if !headerVisible {
                withAnimation(.easeInOut(duration: 0.28)) { headerVisible = true }
            }
            lastOffset = offset
            return
        }

        let delta = offset - lastOffset
        guard abs(delta) > 6 else { return }

        let shouldShow = delta < 0
        if shouldShow != headerVisible {
            withAnimation(.easeInOut(duration: 0.28)) { headerVisible = shouldShow }
        }
        lastOffset = offset
    }
}

/// Vette titel voor de transparante floating header (tabs zonder logo).
struct FloatingHeaderTitle: View {
    let title: String

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: AppFontSize.xl, weight: .black))
                .foregroundStyle(AppColors.textPrimary)
            Spacer(minLength: 0)
        }
    }
}
