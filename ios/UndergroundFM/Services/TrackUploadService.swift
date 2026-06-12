//
//  TrackUploadService.swift
//  UndergroundFM
//
//  Orkestreert het volledige uploadproces:
//  audio + cover + optionele videoclip → Cloudflare R2 via presigned URLs
//  (Edge Function `get-r2-upload-url`) + tracks-row insert.
//

import Foundation

@MainActor
final class TrackUploadService {
    static let shared = TrackUploadService()
    private let sb = SupabaseService.shared
    private let session: URLSession

    private init() {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 120
        self.session = URLSession(configuration: cfg)
    }

    struct UploadInput {
        let audioFileURL: URL
        let audioMimeType: String
        let coverImageData: Data
        let title: String
        let description: String?
        let genreTags: [String]
        let explicit: Bool
        /// Optionele videoclip (mp4/mov). Wordt as-is naar R2 geüpload.
        var videoData: Data? = nil
        var videoMimeType: String = "video/mp4"
    }

    /// Antwoord van de `get-r2-upload-url` Edge Function.
    private struct R2UploadURLs: Decodable {
        let audioUploadUrl: String
        let coverUploadUrl: String
        let audioPublicUrl: String
        let coverPublicUrl: String
        let videoUploadUrl: String?
        let videoPublicUrl: String?
    }

    /// Voert de volledige upload uit en returneert de aangemaakte Track.
    func upload(
        input: UploadInput,
        artistId: String,
        accessToken: String,
        onProgress: @escaping (Double, String) -> Void
    ) async throws -> Track {
        let trackId = UUID().uuidString
        let hasVideo = input.videoData != nil

        // Stap 0: Vraag presigned R2 upload-URLs op bij de Edge Function.
        onProgress(0.0, "Voorbereiden…")
        let audioFileName = input.audioFileURL.lastPathComponent
        let urls = try await fetchUploadURLs(
            artistId: artistId,
            audioFileName: audioFileName.isEmpty ? "track.mp3" : audioFileName,
            coverFileName: "cover.jpg",
            videoFileName: hasVideo ? "clip.mp4" : nil,
            accessToken: accessToken
        )

        // Stap 1: Upload audio (raw bytes, PUT, geen auth-headers).
        onProgress(0.02, "Uploaden audio…")
        let audioData = try Data(contentsOf: input.audioFileURL)
        try await putData(
            audioData,
            to: urls.audioUploadUrl,
            contentType: input.audioMimeType,
            onProgress: { fraction in
                onProgress(0.02 + fraction * 0.58, "Uploaden audio…")
            }
        )

        // Stap 2: Upload cover.
        onProgress(0.60, "Uploaden cover…")
        try await putData(
            input.coverImageData,
            to: urls.coverUploadUrl,
            contentType: "image/jpeg",
            onProgress: { fraction in
                onProgress(0.60 + fraction * 0.30, "Uploaden cover…")
            }
        )

        // Stap 3 (optioneel): Upload videoclip.
        if let videoData = input.videoData, let videoUploadUrl = urls.videoUploadUrl {
            onProgress(0.90, "Uploaden videoclip…")
            try await putData(
                videoData,
                to: videoUploadUrl,
                contentType: input.videoMimeType,
                onProgress: { fraction in
                    onProgress(0.90 + fraction * 0.08, "Uploaden videoclip…")
                }
            )
        }

        // Stap 4: Insert track row met de R2 public URLs.
        onProgress(0.98, "Opslaan…")
        let desc = input.description?.trimmingCharacters(in: .whitespacesAndNewlines)
        var values: [String: Any] = [
            "id": trackId,
            "artist_id": artistId,
            "title": input.title.trimmingCharacters(in: .whitespacesAndNewlines),
            "audio_url": urls.audioPublicUrl,
            "thumbnail_url": urls.coverPublicUrl,
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
        if hasVideo, let videoPublicUrl = urls.videoPublicUrl {
            values["video_url"] = videoPublicUrl
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

    // MARK: - Edge Function

    /// Roept `get-r2-upload-url` aan en retourneert de presigned upload-URLs + public URLs.
    private func fetchUploadURLs(
        artistId: String,
        audioFileName: String,
        coverFileName: String,
        videoFileName: String?,
        accessToken: String
    ) async throws -> R2UploadURLs {
        guard sb.isConfigured else { throw SupabaseError.missingConfig }
        let endpoint = URL(string: "\(sb.url)/functions/v1/get-r2-upload-url")!
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(sb.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = [
            "artistId": artistId,
            "audioFileName": audioFileName,
            "coverFileName": coverFileName
        ]
        // videoFileName alleen meesturen als er daadwerkelijk een clip is.
        if let videoFileName = videoFileName {
            body["videoFileName"] = videoFileName
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await session.data(for: req)
        try SupabaseService.assertOK(resp, data: data)
        do {
            return try JSONDecoder().decode(R2UploadURLs.self, from: data)
        } catch {
            throw SupabaseError.decoding(String(describing: error))
        }
    }

    // MARK: - Presigned PUT

    /// Doet een directe HTTP PUT van de ruwe bytes naar een presigned URL.
    /// Geen extra auth-headers: de URL is al gesigned. Alleen Content-Type.
    private func putData(
        _ data: Data,
        to urlString: String,
        contentType: String,
        onProgress: ((Double) -> Void)? = nil
    ) async throws {
        guard let endpoint = URL(string: urlString) else {
            throw SupabaseError.invalidResponse
        }
        var req = URLRequest(url: endpoint)
        req.httpMethod = "PUT"
        req.setValue(contentType, forHTTPHeaderField: "Content-Type")
        req.httpBody = data

        if let onProgress = onProgress {
            let delegate = PutProgressDelegate(onProgress: onProgress)
            let progressSession = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
            let (responseData, resp) = try await progressSession.data(for: req)
            try SupabaseService.assertOK(resp, data: responseData)
        } else {
            let (responseData, resp) = try await session.data(for: req)
            try SupabaseService.assertOK(resp, data: responseData)
        }
    }
}

// MARK: - Upload Progress Delegate

private final class PutProgressDelegate: NSObject, URLSessionTaskDelegate {
    let onProgress: (Double) -> Void

    init(onProgress: @escaping (Double) -> Void) {
        self.onProgress = onProgress
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard totalBytesExpectedToSend > 0 else { return }
        let fraction = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        Task { @MainActor in
            self.onProgress(fraction)
        }
    }
}
