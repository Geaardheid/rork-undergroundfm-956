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

    var artistProfile: ArtistProfile?
    var isUploadingAvatar: Bool = false
    var isUploadingBanner: Bool = false

    var bio: String = ""
    var artistName: String = ""
    var instagramUrl: String = ""
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
        async let profile: () = loadProfile(artistId: artistId)
        _ = await (tracks, stats, profile)
    }

    func loadProfile(artistId: String) async {
        if let p = try? await ProfileService.shared.fetchProfile(artistId: artistId) {
            artistProfile = p
            artistName = p.artistName
            instagramUrl = p.instagramUrl ?? ""
            bio = p.bio ?? ""
        }
    }

    /// Upload een nieuwe profielfoto; retourneert de nieuwe URL bij succes.
    func uploadAvatar(userId: String, imageData: Data, artistId: String?) async -> String? {
        isUploadingAvatar = true
        defer { isUploadingAvatar = false }
        return try? await ProfileService.shared.updateUserAvatar(userId: userId, imageData: imageData, artistId: artistId)
    }

    /// Upload een nieuwe profielbanner; werkt het lokale profiel direct bij.
    func uploadBanner(artistId: String, imageData: Data) async {
        isUploadingBanner = true
        defer { isUploadingBanner = false }
        guard let url = try? await ProfileService.shared.updateArtistBanner(artistId: artistId, imageData: imageData) else { return }
        if let p = artistProfile {
            artistProfile = ArtistProfile(
                id: p.id, userId: p.userId, artistName: p.artistName, bio: p.bio,
                genreTags: p.genreTags, instagramUrl: p.instagramUrl, instagramHandle: p.instagramHandle,
                bannerUrl: url, verified: p.verified, artistAvatarUrl: p.artistAvatarUrl, users: p.users
            )
        }
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

    /// Sla bio, artiestennaam en Instagram-link in één bewerking op.
    /// Retourneert de opgeslagen naam zodat de auth-store de cache kan bijwerken.
    @discardableResult
    func saveProfile(artistId: String, userId: String) async -> String? {
        isSavingBio = true
        defer { isSavingBio = false }
        try? await ProfileService.shared.updateBio(artistId: artistId, bio: bio)
        let trimmedName = artistName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            try? await ProfileService.shared.updateArtistName(artistId: artistId, userId: userId, name: trimmedName)
        }
        try? await ProfileService.shared.updateInstagram(artistId: artistId, instagramUrl: instagramUrl)
        return trimmedName.isEmpty ? nil : trimmedName
    }

    func deleteTrack(_ track: Track) async {
        myTracks.removeAll { $0.id == track.id }
        try? await ProfileService.shared.deleteTrack(track)
    }

    func updateTrack(_ track: Track, title: String, description: String, videoData: Data? = nil) async {
        try? await ProfileService.shared.updateTrack(trackId: track.id, title: title, description: description)

        // Optioneel: upload (of vervang) de videoclip.
        var newVideoUrl = track.videoUrl
        if let videoData = videoData {
            newVideoUrl = try? await ProfileService.shared.updateTrackVideo(track: track, videoData: videoData, mimeType: "video/mp4")
        }

        if let idx = myTracks.firstIndex(where: { $0.id == track.id }) {
            // Lokale update zodat de UI direct klopt.
            let old = myTracks[idx]
            myTracks[idx] = Track(
                id: old.id, artistId: old.artistId, title: title,
                description: description.isEmpty ? nil : description,
                audioUrl: old.audioUrl, videoUrl: newVideoUrl ?? old.videoUrl, thumbnailUrl: old.thumbnailUrl,
                duration: old.duration, streamCount: old.streamCount, likeCount: old.likeCount,
                genreTags: old.genreTags, explicit: old.explicit, status: old.status,
                weightedMinutesTotal: old.weightedMinutesTotal, createdAt: old.createdAt, artists: old.artists
            )
        }
    }
}
