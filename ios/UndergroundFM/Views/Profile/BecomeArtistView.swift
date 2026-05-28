//
//  BecomeArtistView.swift
//  UndergroundFM
//
//  "Word artiest" — formulier voor een ingelogde fan om een artist-profiel aan te maken.
//

import SwiftUI

struct BecomeArtistGenre: Identifiable, Hashable {
    let id: String
    let label: String
}

struct BecomeArtistView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @Bindable var l10n: L10n

    @State private var artistName: String = ""
    @State private var bio: String = ""
    @State private var instagramUrl: String = ""
    @State private var selectedGenres: Set<String> = []
    @State private var showSuccess: Bool = false

    private let bioLimit: Int = 500

    private var allGenres: [BecomeArtistGenre] {
        [
            .init(id: "rap",   label: "Rap"),
            .init(id: "trap",  label: "Trap"),
            .init(id: "drill", label: "Drill"),
            .init(id: "rb",    label: "R&B"),
            .init(id: "afro",  label: "Afro"),
            .init(id: "house", label: "House"),
        ]
    }

    private var canSubmit: Bool {
        !artistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedGenres.isEmpty &&
        !auth.isLoading
    }

    var body: some View {
        ZStack {
            AppColors.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    header
                    nameField
                    bioField
                    genrePicker
                    instagramField

                    if let msg = auth.errorMessage {
                        Text(msg)
                            .font(.system(size: AppFontSize.sm, weight: .medium))
                            .foregroundStyle(AppColors.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    PrimaryButton(
                        title: l10n.t("artist.submit"),
                        isLoading: auth.isLoading,
                        isDisabled: !canSubmit
                    ) {
                        Task { await submit() }
                    }
                    .padding(.top, AppSpacing.sm)

                    Color.clear.frame(height: 60)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)
            }
        }
        .navigationTitle(l10n.t("artist.becomeTitle"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert(l10n.t("artist.successTitle"), isPresented: $showSuccess) {
            Button(l10n.t("common.done")) { dismiss() }
        } message: {
            Text(l10n.t("artist.successMessage"))
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(l10n.t("artist.becomeTitle"))
                .font(.system(size: AppFontSize.xxl, weight: .black))
                .foregroundStyle(AppColors.textPrimary)
            Text(l10n.t("artist.becomeSubtitle"))
                .font(.system(size: AppFontSize.base, weight: .medium))
                .foregroundStyle(AppColors.textSecond)
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            label(l10n.t("artist.nameLabel"))
            AppTextField(
                placeholder: l10n.t("artist.namePlaceholder"),
                text: $artistName,
                autocapitalize: .words
            )
        }
    }

    private var bioField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                label(l10n.t("artist.bioLabel"))
                Spacer()
                Text("\(bio.count)/\(bioLimit)")
                    .font(.system(size: AppFontSize.xs, weight: .bold))
                    .foregroundStyle(bio.count > bioLimit ? AppColors.error : AppColors.textMuted)
            }
            ZStack(alignment: .topLeading) {
                if bio.isEmpty {
                    Text(l10n.t("artist.bioPlaceholder"))
                        .font(.system(size: AppFontSize.md, weight: .medium))
                        .foregroundStyle(AppColors.textMuted)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, 14)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $bio)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: AppFontSize.md, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, 8)
                    .frame(minHeight: 120)
            }
            .background(AppColors.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .clipShape(.rect(cornerRadius: AppRadius.md))
            .onChange(of: bio) { _, newValue in
                if newValue.count > bioLimit {
                    bio = String(newValue.prefix(bioLimit))
                }
            }
        }
    }

    private var genrePicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            label(l10n.t("artist.genresLabel"))
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

    private var instagramField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            label(l10n.t("artist.instagramLabel"))
            AppTextField(
                placeholder: "https://instagram.com/...",
                text: $instagramUrl,
                keyboard: .URL,
                autocapitalize: .never,
                contentType: .URL
            )
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: AppFontSize.xs, weight: .black))
            .tracking(2)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.textMuted)
    }

    // MARK: - Submit

    private func submit() async {
        let ok = await auth.becomeArtist(
            name: artistName,
            bio: bio,
            genreTags: Array(selectedGenres),
            instagramUrl: instagramUrl
        )
        if ok {
            showSuccess = true
        }
    }
}

// MARK: - Flow chip layout

private struct FlowChips: View {
    let items: [BecomeArtistGenre]
    let isSelected: (BecomeArtistGenre) -> Bool
    let onTap: (BecomeArtistGenre) -> Void

    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 90), spacing: AppSpacing.sm)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: AppSpacing.sm) {
            ForEach(items) { item in
                let selected = isSelected(item)
                Button {
                    onTap(item)
                } label: {
                    Text(item.label)
                        .font(.system(size: AppFontSize.sm, weight: .bold))
                        .foregroundStyle(selected ? AppColors.yellowText : AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(selected ? AppColors.yellow : AppColors.card)
                        .overlay(
                            Capsule().stroke(selected ? AppColors.yellow : AppColors.border, lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(PressableScaleStyle())
            }
        }
    }
}
