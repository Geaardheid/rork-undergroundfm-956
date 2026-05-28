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

    func loadAll() async {
        await loadFeatured()
        await withTaskGroup(of: Void.self) { group in
            for section in GenreSection.all {
                group.addTask { @MainActor in
                    await self.load(section: section)
                }
            }
        }
    }

    func load(section: GenreSection) async {
        sections[section.id] = .loading
        do {
            let tracks = try await service.fetchTracks(
                genre: section.genre,
                orderBy: section.orderBy,
                limit: 10
            )
            sections[section.id] = .loaded(tracks)
        } catch {
            sections[section.id] = .error(error.localizedDescription)
        }
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
