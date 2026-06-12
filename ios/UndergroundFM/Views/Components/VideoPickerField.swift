//
//  VideoPickerField.swift
//  UndergroundFM
//
//  Herbruikbare videoclip-picker (mp4/mov) voor upload + edit.
//  Bestandsgrootte-limiet: zie UploadLimits.maxVideoBytes.
//

import SwiftUI
import PhotosUI

struct VideoPickerField: View {
    @Bindable var l10n: L10n
    /// Toon "Clip vervangen" wanneer er al een clip bestaat.
    var hasExistingClip: Bool = false
    @Binding var videoData: Data?

    @State private var item: PhotosPickerItem?
    @State private var tooLarge: Bool = false
    @State private var isLoading: Bool = false

    private let maxBytes = UploadLimits.maxVideoBytes

    private var hasSelection: Bool { videoData != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            label(l10n.t("upload.videoLabel"))

            PhotosPicker(selection: $item, matching: .videos) {
                HStack(spacing: AppSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .fill(AppColors.yellow.opacity(0.12))
                            .frame(width: 44, height: 44)
                        if isLoading {
                            ProgressView()
                                .tint(AppColors.yellow)
                        } else {
                            Image(systemName: hasSelection ? "film.fill" : "film")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(AppColors.yellow)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(primaryText)
                            .font(.system(size: AppFontSize.md, weight: .semibold))
                            .foregroundStyle(hasSelection ? AppColors.textPrimary : AppColors.textMuted)
                            .lineLimit(1)
                        Text(secondaryText)
                            .font(.system(size: AppFontSize.xs, weight: .medium))
                            .foregroundStyle(AppColors.textMuted)
                    }
                    Spacer()
                    Image(systemName: hasSelection ? "arrow.triangle.2.circlepath" : "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppColors.yellow)
                }
                .padding(AppSpacing.lg)
                .background(AppColors.card)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(hasSelection ? AppColors.yellow.opacity(0.5) : AppColors.border, lineWidth: 1)
                )
                .clipShape(.rect(cornerRadius: AppRadius.md))
            }
            .buttonStyle(PressableScaleStyle())

            if tooLarge {
                Text(l10n.t("upload.videoTooLarge"))
                    .font(.system(size: AppFontSize.xs, weight: .medium))
                    .foregroundStyle(AppColors.error)
            }
        }
        .onChange(of: item) { _, newItem in
            Task { await load(newItem) }
        }
    }

    private var primaryText: String {
        if hasSelection { return l10n.t("upload.videoSelected") }
        if hasExistingClip { return l10n.t("upload.videoReplace") }
        return l10n.t("upload.videoPlaceholder")
    }

    private var secondaryText: String {
        if let data = videoData {
            let mb = Double(data.count) / (1024 * 1024)
            return String(format: "%.1f MB", mb)
        }
        return l10n.t("upload.videoHint")
    }

    private func load(_ newItem: PhotosPickerItem?) async {
        guard let newItem else { return }
        isLoading = true
        tooLarge = false
        defer { isLoading = false }
        guard let data = try? await newItem.loadTransferable(type: Data.self) else { return }
        if data.count > maxBytes {
            tooLarge = true
            videoData = nil
            return
        }
        videoData = data
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: AppFontSize.xs, weight: .black))
            .tracking(2)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.textMuted)
    }
}
