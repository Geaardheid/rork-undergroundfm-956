//
//  TrackUploadService.swift
//  UndergroundFM
//
//  Orkestreert het volledige uploadproces:
//  audio + cover → Supabase Storage + tracks-row insert.
//

import Foundation

@MainActor
final class TrackUploadService {
    static let shared = TrackUploadService()
    private let sb = SupabaseService.shared

    private init() {}

    struct UploadInput {
        let audioFileURL: URL
        let audioMimeType: String
        let coverImageData: Data
        let title: String
        let description: String?
        let genreTags: [String]
        let explicit: Bool
        /// Optionele videoclip (mp4/mov). Wordt geüpload naar de `clips` bucket.
        var videoData: Data? = nil
        var videoMimeType: String = "video/mp4"
    }

    /// Voert de volledige upload uit en returneert de aangemaakte Track.
    func upload(
        input: UploadInput,
        artistId: String,
        accessToken: String,
        onProgress: @escaping (Double, String) -> Void
    ) async throws -> Track {
        let trackId = UUID().uuidString
        let audioPath = "\(artistId)/\(trackId).mp3"
        let coverPath = "\(artistId)/\(trackId)_cover.jpg"

        // Stap 1: Upload audio
        onProgress(0.0, "Uploaden audio…")
        let audioData = try Data(contentsOf: input.audioFileURL)
        let audioURL = try await sb.uploadToStorage(
            bucket: "tracks",
            path: audioPath,
            data: audioData,
            contentType: input.audioMimeType,
            accessToken: accessToken,
            onProgress: { fraction in
                onProgress(fraction * 0.60, "Uploaden audio…")
            }
        )

        // Stap 2: Upload cover
        onProgress(0.60, "Uploaden cover…")
        let thumbnailURL = try await sb.uploadToStorage(
            bucket: "tracks",
            path: coverPath,
            data: input.coverImageData,
            contentType: "image/jpeg",
            accessToken: accessToken,
            onProgress: { fraction in
                onProgress(0.60 + fraction * 0.30, "Uploaden cover…")
            }
        )

        // Stap 3 (optioneel): Upload videoclip naar de `clips` bucket.
        var videoURL: String? = nil
        if let videoData = input.videoData {
            onProgress(0.90, "Uploaden videoclip…")
            videoURL = try await sb.uploadToStorage(
                bucket: "clips",
                path: "\(artistId)/\(trackId).mp4",
                data: videoData,
                contentType: input.videoMimeType,
                accessToken: accessToken,
                onProgress: { fraction in
                    onProgress(0.90 + fraction * 0.08, "Uploaden videoclip…")
                }
            )
        }

        // Stap 4: Insert track row
        onProgress(0.98, "Opslaan…")
        let desc = input.description?.trimmingCharacters(in: .whitespacesAndNewlines)
        var values: [String: Any] = [
            "id": trackId,
            "artist_id": artistId,
            "title": input.title.trimmingCharacters(in: .whitespacesAndNewlines),
            "audio_url": audioURL,
            "thumbnail_url": thumbnailURL,
            "genre_tags": input.genreTags,
            "explicit": input.explicit,
            "status": "live",
            "stream_count": 0,
            "like_count": 0,
            "weighted_minutes_total": 0
        ]
        if let desc = desc, !desc.isEmpty {
            values["description"] = String(desc.prefix(1000))
        }
        if let videoURL = videoURL {
            values["video_url"] = videoURL
        }

        let inserted: [Track] = try await sb.insert(
            Track.self,
            into: "tracks",
            values: values,
            accessToken: accessToken
        )

        onProgress(1.0, "Voltooid!")

        guard let track = inserted.first else {
            throw SupabaseError.invalidResponse
        }
        return track
    }
}
