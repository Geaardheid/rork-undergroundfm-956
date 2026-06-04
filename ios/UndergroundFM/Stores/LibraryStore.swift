//
//  LibraryStore.swift
//  UndergroundFM
//
//  Laadt en beheert de drie secties van de Bibliotheek-tab:
//  gelikete tracks, gevolgde artiesten en eigen playlists.
//

import Foundation

@MainActor
@Observable
final class LibraryStore {
    enum TrackSort: String, CaseIterable, Identifiable {
        case recentlyPlayed
        case recentlyLiked
        case alphabetical

        var id: String { rawValue }

        var labelKey: String {
            switch self {
            case .recentlyPlayed: return "library.sortPlayed"
            case .recentlyLiked:  return "library.sortLiked"
            case .alphabetical:   return "library.sortAZ"
            }
        }
    }

    // Tracks
    private(set) var likedTracks: [Track] = []
    var sort: TrackSort = .recentlyPlayed { didSet { applySort() } }
    private var playOrder: [String] = []

    // Artists
    private(set) var followedArtists: [ArtistProfile] = []

    // Playlists
    private(set) var playlists: [Playlist] = []
    private(set) var playlistCovers: [String: [String]] = [:]

    private(set) var isLoading: Bool = false

    private let likes = LikesService.shared
    private let follows = FollowService.shared
    private let playlistService = PlaylistService.shared
    private let library = LibraryService.shared

    /// Laad alles voor de gegeven gebruiker.
    func loadAll(userId: String) async {
        isLoading = true
        async let likedTask = likes.fetchLikedTracks(userId: userId)
        async let orderTask = library.fetchRecentlyPlayedTrackIds(userId: userId)
        async let artistsTask = follows.fetchFollowedArtists(userId: userId)
        async let playlistsTask = playlistService.fetchPlaylists(userId: userId)

        likedTracks = (try? await likedTask) ?? []
        playOrder = (try? await orderTask) ?? []
        followedArtists = (try? await artistsTask) ?? []
        playlists = (try? await playlistsTask) ?? []
        applySort()
        isLoading = false

        await loadCovers()
    }

    /// Herlaad de playlists (na aanmaken/verwijderen).
    func reloadPlaylists(userId: String) async {
        playlists = (try? await playlistService.fetchPlaylists(userId: userId)) ?? []
        await loadCovers()
    }

    private func loadCovers() async {
        for playlist in playlists where playlistCovers[playlist.id] == nil {
            if let covers = try? await playlistService.fetchCoverUrls(playlistId: playlist.id) {
                playlistCovers[playlist.id] = covers
            }
        }
    }

    /// Unlike een track en verwijder hem direct uit de lijst.
    func unlike(track: Track, userId: String) async {
        likedTracks.removeAll { $0.id == track.id }
        try? await likes.unlike(trackId: track.id, userId: userId)
    }

    func covers(for playlistId: String) -> [String] {
        playlistCovers[playlistId] ?? []
    }

    private func applySort() {
        switch sort {
        case .recentlyLiked:
            // fetchLikedTracks geeft al created_at.desc terug — niets te doen.
            break
        case .alphabetical:
            likedTracks.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .recentlyPlayed:
            let rank: [String: Int] = Dictionary(
                uniqueKeysWithValues: playOrder.enumerated().map { ($1, $0) }
            )
            likedTracks.sort {
                (rank[$0.id] ?? Int.max) < (rank[$1.id] ?? Int.max)
            }
        }
    }
}
