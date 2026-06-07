//
//  FeedStore.swift
//  UndergroundFM
//
//  Laadt en cachet tracks per genre-sectie + featured banner.
//

import Foundation

@MainActor
@Observable
final class FeedStore {
    enum SectionState {
        case idle
        case loading
        case loaded([Track])
        case error(String)
    }

    var sections: [String: SectionState] = [:]
    var featured: Track?
    var featuredError: String?
    var isFeaturedLoading: Bool = false

    private let service = TracksService.shared

    func state(for sectionId: String) -> SectionState {
        sections[sectionId] ?? .idle
    }

    /// Laadt featured + secties sequentieel (geen gelijktijdige task-cancellation).
    /// Bestaande data blijft zichtbaar tot nieuwe data succesvol binnen is.
    ///
    /// `preferences`: niet-lege lijst van genre-keys → laad alleen die secties.
    /// Lege lijst → laad alle secties (nooit een lege feed). De featured banner
    /// laadt altijd, ongeacht de voorkeuren.
    func loadAll(preferences: [String] = []) async {
        await loadFeatured()
        for section in sections(for: preferences) {
            await load(section: section)
            // Kleine adempauze zodat opeenvolgende fetches elkaar niet verdringen.
            try? await Task.sleep(for: .milliseconds(80))
        }
    }

    /// Zichtbare secties op basis van de fan-voorkeuren. Lege voorkeuren = alles.
    func sections(for preferences: [String]) -> [GenreSection] {
        guard !preferences.isEmpty else { return GenreSection.all }
        let prefSet = Set(preferences)
        let filtered = GenreSection.all.filter { prefSet.contains($0.genre) }
        return filtered.isEmpty ? GenreSection.all : filtered
    }

    func load(section: GenreSection) async {
        // Alleen de loading-spinner tonen als er nog geen data is.
        // Heeft de sectie al data, dan blijft die staan tijdens de refresh.
        if !hasData(for: section.id) {
            sections[section.id] = .loading
        }
        do {
            let tracks = try await service.fetchTracks(
                genre: section.genre,
                orderBy: section.orderBy,
                limit: 10
            )
            sections[section.id] = .loaded(tracks)
        } catch {
            // Bewaar bestaande data bij een fout (bv. refresh-cancellatie):
            // toon alleen de error-staat als er niets te tonen valt.
            if !hasData(for: section.id) {
                sections[section.id] = .error(error.localizedDescription)
            }
        }
    }

    /// Een sectie geldt als "geladen" zodra ze ooit succesvol klaar is — ook met een
    /// lege lijst. Zo blijft een lege sectie de empty-state tonen i.p.v. bij een
    /// volgende (transient) fout naar de error-staat te springen.
    private func hasData(for sectionId: String) -> Bool {
        if case .loaded = sections[sectionId] {
            return true
        }
        return false
    }

    func loadFeatured() async {
        isFeaturedLoading = true
        featuredError = nil
        do {
            featured = try await service.fetchFeatured()
        } catch {
            featuredError = error.localizedDescription
        }
        isFeaturedLoading = false
    }
}
