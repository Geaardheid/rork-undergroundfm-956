//
//  UploadTrackView.swift
//  UndergroundFM
//
//  Audio-only upload scherm voor artiesten.
//  Pick audio file + cover image + vul metadata in → upload naar Supabase.
//

import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import AVFoundation

struct UploadTrackView: View {
    @Environment(AuthStore.self) private var auth
    @Bindable var l10n: L10n

    // Audio picker
    @State private var audioURL: URL?
    @State private var audioFileName: String?
    @State private var audioBitrate: Int?
    @State private var audioQualityMessage: String?
    @State private var audioQualityColor: Color = .clear

    // Cover picker
    @State private var coverItem: PhotosPickerItem?
    @State private var coverImageData: Data?

    // Bestandsgrootte-validatie
    @State private var audioTooLarge: Bool = false
    @State private var coverTooLarge: Bool = false

    // Video picker (optioneel)
    @State private var videoData: Data?

    // Form fields
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedGenres: Set<String> = []
    @State private var isExplicit: Bool = false

    // Upload progress
    @State private var uploadFraction: Double = 0
    @State private var uploadLabel: String = ""
    @State private var isUploading: Bool = false
    @State private var uploadError: String?
    @State private var showSuccess: Bool = false

    // Document picker
    @State private var showAudioPicker: Bool = false

    private let allGenres: [GenreChip] = [
        .init(id: "rap", label: "Rap"),
        .init(id: "trap", label: "Trap"),
        .init(id: "drill", label: "Drill"),
        .init(id: "rb", label: "R&B"),
        .init(id: "afro", label: "Afro"),
        .init(id: "house", label: "House"),
    ]

    private var canUpload: Bool {
        audioURL != nil &&
        coverImageData != nil &&
        !audioTooLarge &&
        !coverTooLarge &&
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isUploading
    }

    var body: some View {
        NavigationStack {
            FloatingHeaderScreen(header: { FloatingHeaderTitle(title: l10n.t("tab.upload")) }) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    header
                    audioPickerCard
                    coverPickerCard
                    VideoPickerField(l10n: l10n, videoData: $videoData)
                    titleField
                    descriptionField
                    genrePicker
                    explicitToggle

                    if let error = uploadError {
                        Text(error)
                            .font(.system(size: AppFontSize.sm, weight: .medium))
                            .foregroundStyle(AppColors.error)
                    }

                    uploadButton

                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
            }
            .toolbar(.hidden, for: .navigationBar)
            .fileImporter(
                isPresented: $showAudioPicker,
                allowedContentTypes: [.mp3, .mpeg4Audio, .audio],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        _ = url.startAccessingSecurityScopedResource()
                        Task { await validateAndSetAudio(url) }
                    }
                case .failure:
                    break
                }
            }
            .onChange(of: coverItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        if data.count > UploadLimits.maxCoverBytes {
                            coverTooLarge = true
                            coverImageData = nil
                            HapticManager.error()
                        } else {
                            coverTooLarge = false
                            coverImageData = data
                        }
                    }
                }
            }
            .alert(l10n.t("upload.successTitle"), isPresented: $showSuccess) {
                Button(l10n.t("common.done")) {
                    resetForm()
                }
            } message: {
                Text(l10n.t("upload.successMessage"))
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(l10n.t("upload.title"))
                .font(.system(size: AppFontSize.xxl, weight: .black))
                .foregroundStyle(AppColors.textPrimary)
            Text(l10n.t("upload.subtitle"))
                .font(.system(size: AppFontSize.base, weight: .medium))
                .foregroundStyle(AppColors.textSecond)
        }
    }

    private var audioPickerCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            label(l10n.t("upload.audioLabel"))

            Button {
                showAudioPicker = true
            } label: {
                HStack(spacing: AppSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .fill(AppColors.yellow.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: audioURL != nil ? "waveform.circle.fill" : "music.note.list")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AppColors.yellow)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(audioFileName ?? l10n.t("upload.audioPlaceholder"))
                            .font(.system(size: AppFontSize.md, weight: .semibold))
                            .foregroundStyle(audioURL != nil ? AppColors.textPrimary : AppColors.textMuted)
                            .lineLimit(1)
                        if audioURL != nil {
                            Text(l10n.t("upload.audioTapToChange"))
                                .font(.system(size: AppFontSize.xs, weight: .medium))
                                .foregroundStyle(AppColors.textMuted)
                        }
                    }
                    Spacer()
                    Image(systemName: audioURL != nil ? "arrow.triangle.2.circlepath" : "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppColors.yellow)
                }
                .padding(AppSpacing.lg)
                .background(AppColors.card)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(audioURL != nil ? AppColors.yellow.opacity(0.5) : AppColors.border, lineWidth: 1)
                )
                .clipShape(.rect(cornerRadius: AppRadius.md))
            }
            .buttonStyle(PressableScaleStyle())

            if audioTooLarge {
                Text(l10n.t("upload.audioTooLarge"))
                    .font(.system(size: AppFontSize.xs, weight: .bold))
                    .foregroundStyle(AppColors.error)
            } else if let msg = audioQualityMessage {
                Text(msg)
                    .font(.system(size: AppFontSize.xs, weight: .bold))
                    .foregroundStyle(audioQualityColor)
            }
        }
    }

    private var coverPickerCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            label(l10n.t("upload.coverLabel"))

            PhotosPicker(selection: $coverItem, matching: .images) {
                HStack(spacing: AppSpacing.md) {
                    if let data = coverImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 34)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: AppRadius.sm)
                                .fill(AppColors.yellow.opacity(0.12))
                                .frame(width: 60, height: 34)
                            Image(systemName: "photo")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(AppColors.yellow)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(coverImageData != nil ? l10n.t("upload.coverSelected") : l10n.t("upload.coverPlaceholder"))
                            .font(.system(size: AppFontSize.md, weight: .semibold))
                            .foregroundStyle(coverImageData != nil ? AppColors.textPrimary : AppColors.textMuted)
                        Text(coverTooLarge ? l10n.t("upload.coverTooLarge") : "16:9")
                            .font(.system(size: AppFontSize.xs, weight: .medium))
                            .foregroundStyle(coverTooLarge ? AppColors.error : AppColors.textMuted)
                    }
                    Spacer()
                    Image(systemName: coverImageData != nil ? "checkmark.circle.fill" : "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppColors.yellow)
                }
                .padding(AppSpacing.lg)
                .background(AppColors.card)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(coverImageData != nil ? AppColors.yellow.opacity(0.5) : AppColors.border, lineWidth: 1)
                )
                .clipShape(.rect(cornerRadius: AppRadius.md))
            }
            .buttonStyle(PressableScaleStyle())
        }
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            label(l10n.t("upload.titleLabel"))
            AppTextField(
                placeholder: l10n.t("upload.titlePlaceholder"),
                text: $title,
                autocapitalize: .sentences
            )
        }
    }

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            label(l10n.t("upload.descriptionLabel"))
            AppTextField(
                placeholder: l10n.t("upload.descriptionPlaceholder"),
                text: $description,
                autocapitalize: .sentences
            )
        }
    }

    private var genrePicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            label(l10n.t("upload.genresLabel"))
            FlowChips(
                items: allGenres,
                isSelected: { selectedGenres.contains($0.id) },
                onTap: { genre in
                    if selectedGenres.contains(genre.id) {
                        selectedGenres.remove(genre.id)
                    } else {
                        selectedGenres.insert(genre.id)
                    }
                }
            )
        }
    }

    private var explicitToggle: some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(l10n.t("upload.explicitLabel"))
                    .font(.system(size: AppFontSize.md, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Text(l10n.t("upload.explicitHint"))
                    .font(.system(size: AppFontSize.xs, weight: .medium))
                    .foregroundStyle(AppColors.textMuted)
            }
            Spacer()
            Toggle("", isOn: $isExplicit)
                .labelsHidden()
                .tint(AppColors.yellow)
        }
        .padding(AppSpacing.lg)
        .background(AppColors.card)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .clipShape(.rect(cornerRadius: AppRadius.md))
    }

    private var uploadButton: some View {
        VStack(spacing: AppSpacing.md) {
            if isUploading {
                VStack(spacing: AppSpacing.md) {
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColors.border)
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColors.yellow)
                                .frame(width: geo.size.width * uploadFraction, height: 6)
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: uploadFraction)
                        }
                    }
                    .frame(height: 6)

                    Text(uploadLabel)
                        .font(.system(size: AppFontSize.sm, weight: .medium))
                        .foregroundStyle(AppColors.textSecond)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                .padding(.vertical, AppSpacing.sm)
            } else {
                Button {
                    Task { await startUpload() }
                } label: {
                    ZStack {
                        Text(l10n.t("upload.uploadButton"))
                            .font(.system(size: AppFontSize.md, weight: .bold))
                            .foregroundStyle(canUpload ? AppColors.yellowText : AppColors.yellowText.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(canUpload ? AppColors.yellow : AppColors.yellowDark.opacity(0.5))
                    .clipShape(.rect(cornerRadius: AppRadius.md))
                }
                .buttonStyle(PressableScaleStyle())
                .disabled(!canUpload)
            }
        }
        .padding(.top, AppSpacing.sm)
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: AppFontSize.xs, weight: .black))
            .tracking(2)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.textMuted)
    }

    // MARK: - Audio quality validation

    private func validateAndSetAudio(_ url: URL) async {
        let asset = AVURLAsset(url: url)
        var kbps: Int?
        if let track = try? await asset.loadTracks(withMediaType: .audio).first,
           let rate = try? await track.load(.estimatedDataRate), rate > 0 {
            kbps = Int((rate / 1000).rounded())
        }
        await MainActor.run {
            let ext = url.pathExtension.lowercased()
            if let k = kbps {
                if k < 192 {
                    uploadError = String(format: l10n.t("upload.qualityTooLow"), k)
                    HapticManager.error()
                    audioURL = nil
                    audioFileName = nil
                    audioBitrate = nil
                    audioQualityMessage = nil
                    return
                } else if k < 256 {
                    audioQualityMessage = String(format: l10n.t("upload.qualityOk"), k)
                    audioQualityColor = AppColors.yellow
                } else {
                    audioQualityMessage = String(format: l10n.t("upload.qualityHigh"), k)
                    audioQualityColor = .green
                }
                if ext == "mp3" && k >= 256 {
                    audioQualityMessage = (audioQualityMessage ?? "") + " \u{00B7} " + l10n.t("upload.preferAAC")
                }
                audioBitrate = k
            } else {
                audioQualityMessage = nil
                audioBitrate = nil
            }
            uploadError = nil
            audioURL = url
            audioFileName = url.lastPathComponent
        }
    }

    // MARK: - Upload logic

    private func startUpload() async {
        guard let audioURL = audioURL,
              let coverData = coverImageData,
              let artistId = auth.artistId,
              let token = SessionStore.shared.session?.accessToken else {
            uploadError = l10n.t("errors.unknown")
            return
        }

        isUploading = true
        uploadError = nil
        uploadFraction = 0
        uploadLabel = ""

        // Determine MIME type
        let mimeType: String
        switch audioURL.pathExtension.lowercased() {
        case "mp3": mimeType = "audio/mpeg"
        case "m4a": mimeType = "audio/mp4"
        default:    mimeType = "audio/mpeg"
        }

        let input = TrackUploadService.UploadInput(
            audioFileURL: audioURL,
            audioMimeType: mimeType,
            coverImageData: coverData,
            title: title,
            description: description.isEmpty ? nil : description,
            genreTags: Array(selectedGenres),
            explicit: isExplicit,
            videoData: videoData,
            videoMimeType: "video/mp4"
        )

        do {
            _ = try await TrackUploadService.shared.upload(
                input: input,
                artistId: artistId,
                accessToken: token,
                onProgress: { fraction, label in
                    self.uploadFraction = fraction
                    self.uploadLabel = label
                }
            )
            isUploading = false
            showSuccess = true
            HapticManager.success()
        } catch {
            isUploading = false
            uploadError = error.localizedDescription
            HapticManager.error()
        }
    }

    private func resetForm() {
        audioURL = nil
        audioFileName = nil
        audioBitrate = nil
        audioQualityMessage = nil
        audioQualityColor = .clear
        coverItem = nil
        coverImageData = nil
        videoData = nil
        title = ""
        description = ""
        selectedGenres = []
        isExplicit = false
        uploadFraction = 0
        uploadLabel = ""
        uploadError = nil
    }
}
