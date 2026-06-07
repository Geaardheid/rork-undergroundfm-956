//
//  GenrePickerGrid.swift
//  UndergroundFM
//
//  Herbruikbaar genre-keuzegrid. Zelfde visuele taal als het zoekscherm:
//  emoji, kleurtint per genre, cover-art. Meerkeuze met gele rand + vinkje.
//  Gebruikt in de fan-registratie en in Instellingen ("Mijn genres").
//

import SwiftUI

struct GenrePickerGrid: View {
    @Binding var selected: Set<String>
    /// Compacter rooster (kleinere tegels) zodat alle zes zonder veel scrollen passen.
    var compact: Bool = false

    @State private var covers: [String: String] = [:]

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: AppSpacing.md),
            GridItem(.flexible(), spacing: AppSpacing.md)
        ]
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.md) {
            ForEach(GenreSection.all) { section in
                Button {
                    toggle(section.genre)
                } label: {
                    GenrePickerTile(
                        emoji: section.emoji,
                        name: GenreDisplay.name(section.genre),
                        tint: GenreDisplay.tint(section.genre),
                        coverUrl: covers[section.genre],
                        isSelected: selected.contains(section.genre),
                        height: compact ? 88 : 110
                    )
                }
                .buttonStyle(PressableScaleStyle())
            }
        }
        .task { await loadCovers() }
    }

    private func toggle(_ genre: String) {
        HapticManager.selection()
        if selected.contains(genre) {
            selected.remove(genre)
        } else {
            selected.insert(genre)
        }
    }

    /// Haal per genre de cover van de meest beluisterde track op (voor de tegels).
    private func loadCovers() async {
        for section in GenreSection.all where covers[section.genre] == nil {
            if let rows = try? await TracksService.shared.fetchTracks(
                genre: section.genre,
                orderBy: .trending,
                limit: 1
            ), let cover = rows.first?.thumbnailUrl {
                covers[section.genre] = cover
            }
        }
    }
}

// MARK: - Tile

private struct GenrePickerTile: View {
    let emoji: String
    let name: String
    let tint: Color
    let coverUrl: String?
    let isSelected: Bool
    let height: CGFloat

    var body: some View {
        Color(AppColors.card)
            .frame(height: height)
            .overlay {
                if let coverUrl, let u = URL(string: coverUrl) {
                    AsyncImage(url: u) { phase in
                        if case .success(let img) = phase {
                            img.resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
            .overlay(
                LinearGradient(
                    colors: [tint.opacity(0.92), tint.opacity(0.55), .black.opacity(0.65)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .topLeading) {
                Text(name)
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                    .padding(AppSpacing.md)
            }
            .overlay(alignment: .bottomTrailing) {
                Text(emoji)
                    .font(.system(size: 30))
                    .rotationEffect(.degrees(12))
                    .padding(.trailing, AppSpacing.sm)
                    .padding(.bottom, 2)
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(AppColors.yellow)
                        .background(Circle().fill(.black.opacity(0.45)))
                        .padding(AppSpacing.sm)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .clipShape(.rect(cornerRadius: AppRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .stroke(AppColors.yellow, lineWidth: isSelected ? 2.5 : 0)
            )
            .shadow(color: AppColors.yellow.opacity(isSelected ? 0.4 : 0), radius: 14)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Display helpers (gedeeld met SearchView-stijl)

enum GenreDisplay {
    static func name(_ raw: String) -> String {
        switch raw.lowercased() {
        case "rb", "r&b": return "R&B"
        default: return raw.prefix(1).uppercased() + raw.dropFirst()
        }
    }

    /// Subtiele kleurtint per genre voor de tegel-gradient.
    static func tint(_ raw: String) -> Color {
        switch raw.lowercased() {
        case "rap":   return Color(hex: 0x7A1F1F)
        case "drill": return Color(hex: 0x1F2F7A)
        case "afro":  return Color(hex: 0x1F5A2E)
        case "trap":  return Color(hex: 0x4A1F7A)
        case "rb":    return Color(hex: 0x8A4A12)
        case "house": return Color(hex: 0x12605A)
        default:      return AppColors.cardHover
        }
    }
}
