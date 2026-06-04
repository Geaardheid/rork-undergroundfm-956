//
//  ArtistTrackRow.swift
//  UndergroundFM
//
//  Rij in de "Mijn tracks" lijst + custom swipe-to-delete container + edit-sheet.
//

import SwiftUI

struct ArtistTrackRow: View {
    let track: Track
    var isCurrent: Bool = false

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            TrackThumbnail(url: track.thumbnailUrl, cornerRadius: AppRadius.sm)
                .frame(width: 72)

            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.system(size: AppFontSize.base, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                HStack(spacing: AppSpacing.md) {
                    Label("\(track.streamCount)", systemImage: "play.fill")
                    if let d = track.duration, d > 0 {
                        Label(formatDuration(d), systemImage: "clock")
                    }
                    if track.status != "live" {
                        Text(track.status.uppercased())
                            .font(.system(size: AppFontSize.xs, weight: .black))
                            .foregroundStyle(AppColors.warning)
                    }
                }
                .font(.system(size: AppFontSize.xs, weight: .semibold))
                .foregroundStyle(AppColors.textSecond)
            }
            Spacer(minLength: 0)
            Image(systemName: "pencil")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(AppSpacing.sm)
        .frame(maxWidth: .infinity)
        .background(isCurrent ? AppColors.yellow.opacity(0.08) : AppColors.card)
        .overlay(alignment: .leading) {
            if isCurrent {
                AppColors.yellow
                    .frame(width: 4)
                    .clipShape(.rect(cornerRadius: 2))
            }
        }
        .clipShape(.rect(cornerRadius: AppRadius.md))
        .contentShape(Rectangle())
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

/// Lichtgewicht swipe-to-delete container (links vegen onthult een rode knop).
struct SwipeToDeleteRow<Content: View>: View {
    let deleteLabel: String
    let onDelete: () async -> Void
    @ViewBuilder let content: Content

    @State private var offsetX: CGFloat = 0
    @State private var isConfirming: Bool = false
    private let actionWidth: CGFloat = 88

    var body: some View {
        ZStack(alignment: .trailing) {
            Button {
                Task {
                    await onDelete()
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text(deleteLabel)
                        .font(.system(size: AppFontSize.xs, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(width: actionWidth)
                .frame(maxHeight: .infinity)
                .background(AppColors.error)
                .clipShape(.rect(cornerRadius: AppRadius.md))
            }
            .buttonStyle(.plain)
            .opacity(offsetX < -8 ? 1 : 0)

            content
                .offset(x: offsetX)
                .gesture(
                    DragGesture(minimumDistance: 12)
                        .onChanged { value in
                            if value.translation.width < 0 {
                                offsetX = max(value.translation.width, -actionWidth)
                            } else if isConfirming {
                                offsetX = min(-actionWidth + value.translation.width, 0)
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if value.translation.width < -actionWidth / 2 {
                                    offsetX = -actionWidth
                                    isConfirming = true
                                } else {
                                    offsetX = 0
                                    isConfirming = false
                                }
                            }
                        }
                )
        }
    }
}

struct EditTrackSheet: View {
    let track: Track
    @Bindable var l10n: L10n
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var description: String

    init(track: Track, l10n: L10n, onSave: @escaping (String, String) -> Void) {
        self.track = track
        self.l10n = l10n
        self.onSave = onSave
        _title = State(initialValue: track.title)
        _description = State(initialValue: track.description ?? "")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text(l10n.t("profile.editTrack"))
                    .font(.system(size: AppFontSize.lg, weight: .black))
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.top, AppSpacing.lg)

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ProfileSectionHeader(title: l10n.t("upload.titleLabel"))
                    AppTextField(
                        placeholder: l10n.t("upload.titlePlaceholder"),
                        text: $title
                    )
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ProfileSectionHeader(title: l10n.t("upload.descriptionLabel"))
                    TextEditor(text: $description)
                        .scrollContentBackground(.hidden)
                        .frame(height: 100)
                        .padding(AppSpacing.sm)
                        .background(AppColors.card)
                        .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(AppColors.border, lineWidth: 1))
                        .clipShape(.rect(cornerRadius: AppRadius.md))
                        .foregroundStyle(AppColors.textPrimary)
                }

                PrimaryButton(
                    title: l10n.t("common.done"),
                    isDisabled: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    onSave(title.trimmingCharacters(in: .whitespacesAndNewlines), description)
                    dismiss()
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }
}
