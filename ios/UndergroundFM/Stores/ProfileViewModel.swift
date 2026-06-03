//
//  ProfileViewModel.swift
//  UndergroundFM
//
//  Laadt data voor het eigen profiel: gelikte tracks (fan) en
//  artiest-stats + eigen tracks (artiest).
//

import Foundation
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    var likedTracks: [Track] = []
    var likedLoading: Bool = false

    var myTracks: [Track] = []
    var tracksLoading: Bool = false

    var stats: ArtistMonthStats = .empty
    var statsLoading: Bool = false

    var bio: String = ""
    var isSavingBio: Bool = false

    // MARK: - Fan

    func loadLikedTracks(userId: String) async {
        likedLoading = true
        defer { likedLoading = false }
        likedTracks = (try? await LikesService.shared.fetchLikedTracks(userId: userId)) ?? []
    }

    // MARK: - Artist

    func loadArtistData(artistId: String) async {
        async let tracks: () = loadMyTracks(artistId: artistId)
        async let stats: () = loadStats(artistId: artistId)
        _ = await (tracks, stats)
    }

    func loadMyTracks(artistId: String) async {
        tracksLoading = true
        defer { tracksLoading = false }
        myTracks = (try? await ProfileService.shared.fetchTracks(artistId: artistId, liveOnly: false)) ?? []
    }

    func loadStats(artistId: String) async {
        statsLoading = true
        defer { statsLoading = false }
        if let s = try? await SceneStatsService.shared.fetchStats(for: artistId) {
            stats = s
        }
    }

    func saveBio(artistId: String) async {
        isSavingBio = true
        defer { isSavingBio = false }
        try? await ProfileService.shared.updateBio(artistId: artistId, bio: bio)
    }

    func deleteTrack(_ track: Track) async {
        myTracks.removeAll { $0.id == track.id }
        try? await ProfileService.shared.deleteTrack(track)
    }

    func updateTrack(_ track: Track, title: String, description: String) async {
        try? await ProfileService.shared.updateTrack(trackId: track.id, title: title, description: description)
        if let idx = myTracks.firstIndex(where: { $0.id == track.id }) {
            // Lokale update zodat de UI direct klopt.
            let old = myTracks[idx]
            myTracks[idx] = Track(
                id: old.id, artistId: old.artistId, title: title,
                description: description.isEmpty ? nil : description,
                audioUrl: old.audioUrl, videoUrl: old.videoUrl, thumbnailUrl: old.thumbnailUrl,
                duration: old.duration, streamCount: old.streamCount, likeCount: old.likeCount,
                genreTags: old.genreTags, explicit: old.explicit, status: old.status,
                weightedMinutesTotal: old.weightedMinutesTotal, createdAt: old.createdAt, artists: old.artists
            )
        }
    }
}
