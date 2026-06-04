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

    /// Laadt featured + alle secties sequentieel (geen gelijktijdige task-cancellation).
    /// Bestaande data blijft zichtbaar tot nieuwe data succesvol binnen is.
    func loadAll() async {
        await loadFeatured()
        for section in GenreSection.all {
            await load(section: section)
            // Kleine adempauze zodat opeenvolgende fetches elkaar niet verdringen.
            try? await Task.sleep(for: .milliseconds(80))
        }
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

    private func hasData(for sectionId: String) -> Bool {
        if case .loaded(let tracks) = sections[sectionId], !tracks.isEmpty {
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
