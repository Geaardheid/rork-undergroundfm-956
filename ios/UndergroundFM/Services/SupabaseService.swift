//
//  SupabaseService.swift
//  UndergroundFM
//
//  Lichtgewicht Supabase REST client (auth + tabel queries) zonder SPM dependency.
//

import Foundation

nonisolated enum SupabaseError: LocalizedError {
    case missingConfig
    case http(Int, String)
    case decoding(String)
    case invalidResponse
    case message(String)

    var errorDescription: String? {
        switch self {
        case .missingConfig: return "Supabase niet geconfigureerd"
        case .http(let code, let msg): return "HTTP \(code): \(msg)"
        case .decoding(let m): return "Decoding error: \(m)"
        case .invalidResponse: return "Ongeldig antwoord van server"
        case .message(let m): return m
        }
    }
}

nonisolated final class SupabaseService: @unchecked Sendable {
    static let shared = SupabaseService()

    let url: String
    let anonKey: String
    private let session: URLSession

    private init() {
        self.url = SupabaseConfig.url
        self.anonKey = SupabaseConfig.anonKey
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 20
        self.session = URLSession(configuration: cfg)
    }

    var isConfigured: Bool {
        !url.isEmpty && !anonKey.isEmpty
    }

    // MARK: - Auth

    struct SignUpResponse: Decodable {
        let access_token: String?
        let refresh_token: String?
        let user: AuthUser?
    }

    struct AuthUser: Decodable {
        let id: String
        let email: String?
    }

    struct SignInResponse: Decodable {
        let access_token: String
        let refresh_token: String
        let user: AuthUser
    }

    func signUp(email: String, password: String) async throws -> (userId: String, accessToken: String?, refreshToken: String?) {
        guard isConfigured else { throw SupabaseError.missingConfig }
        let endpoint = URL(string: "\(url)/auth/v1/signup")!
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        let body: [String: Any] = ["email": email, "password": password]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await session.data(for: req)
        try Self.assertOK(resp, data: data)
        let decoded = try JSONDecoder().decode(SignUpResponse.self, from: data)
        guard let user = decoded.user else { throw SupabaseError.invalidResponse }
        return (user.id, decoded.access_token, decoded.refresh_token)
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        guard isConfigured else { throw SupabaseError.missingConfig }
        let endpoint = URL(string: "\(url)/auth/v1/token?grant_type=password")!
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        let body: [String: Any] = ["email": email, "password": password]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await session.data(for: req)
        try Self.assertOK(resp, data: data)
        let decoded = try JSONDecoder().decode(SignInResponse.self, from: data)
        return AuthSession(
            accessToken: decoded.access_token,
            refreshToken: decoded.refresh_token,
            userId: decoded.user.id,
            email: decoded.user.email ?? email
        )
    }

    /// Exchange a stored refresh token for a fresh session (access tokens expire ~1h).
    func refreshSession(refreshToken: String) async throws -> AuthSession {
        guard isConfigured else { throw SupabaseError.missingConfig }
        let endpoint = URL(string: "\(url)/auth/v1/token?grant_type=refresh_token")!
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        let body: [String: Any] = ["refresh_token": refreshToken]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await session.data(for: req)
        try Self.assertOK(resp, data: data)
        let decoded = try JSONDecoder().decode(SignInResponse.self, from: data)
        return AuthSession(
            accessToken: decoded.access_token,
            refreshToken: decoded.refresh_token,
            userId: decoded.user.id,
            email: decoded.user.email ?? ""
        )
    }

    /// Werk het wachtwoord van de ingelogde gebruiker bij (GoTrue PUT /user).
    func updatePassword(newPassword: String, accessToken: String) async throws {
        guard isConfigured else { throw SupabaseError.missingConfig }
        let endpoint = URL(string: "\(url)/auth/v1/user")!
        var req = URLRequest(url: endpoint)
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["password": newPassword])
        let (data, resp) = try await session.data(for: req)
        try Self.assertOK(resp, data: data)
    }

    func signOut(accessToken: String) async throws {
        guard isConfigured else { throw SupabaseError.missingConfig }
        let endpoint = URL(string: "\(url)/auth/v1/logout")!
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (_, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200..<300).contains(http.statusCode) && http.statusCode != 204 {
            throw SupabaseError.http(http.statusCode, "logout failed")
        }
    }

    // MARK: - REST helpers (PostgREST)

    private func restRequest(
        path: String,
        method: String,
        accessToken: String?,
        query: [String: String] = [:],
        body: Any? = nil,
        prefer: String? = nil
    ) throws -> URLRequest {
        guard isConfigured else { throw SupabaseError.missingConfig }
        var comps = URLComponents(string: "\(url)/rest/v1/\(path)")!
        if !query.isEmpty {
            comps.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        var req = URLRequest(url: comps.url!)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        if let token = accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let prefer = prefer {
            req.setValue(prefer, forHTTPHeaderField: "Prefer")
        }
        if let body = body {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        return req
    }

    /// Generic select
    func select<T: Decodable>(
        _ type: T.Type,
        from table: String,
        query: [String: String] = [:],
        accessToken: String? = nil
    ) async throws -> [T] {
        let req = try restRequest(path: table, method: "GET", accessToken: accessToken, query: query)
        let (data, resp) = try await session.data(for: req)
        try Self.assertOK(resp, data: data)
        do {
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            throw SupabaseError.decoding(String(describing: error))
        }
    }

    /// Insert row(s). Returns inserted rows.
    @discardableResult
    func insert<T: Decodable>(
        _ type: T.Type,
        into table: String,
        values: [String: Any],
        accessToken: String? = nil
    ) async throws -> [T] {
        let req = try restRequest(
            path: table,
            method: "POST",
            accessToken: accessToken,
            body: [values],
            prefer: "return=representation"
        )
        let (data, resp) = try await session.data(for: req)
        try Self.assertOK(resp, data: data)
        do {
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            throw SupabaseError.decoding(String(describing: error))
        }
    }

    /// Update rows matching query
    func update(
        table: String,
        query: [String: String],
        values: [String: Any],
        accessToken: String?
    ) async throws {
        let req = try restRequest(
            path: table,
            method: "PATCH",
            accessToken: accessToken,
            query: query,
            body: values
        )
        let (data, resp) = try await session.data(for: req)
        try Self.assertOK(resp, data: data)
    }

    /// Delete rows matching query
    func delete(
        table: String,
        query: [String: String],
        accessToken: String?
    ) async throws {
        let req = try restRequest(
            path: table,
            method: "DELETE",
            accessToken: accessToken,
            query: query
        )
        let (data, resp) = try await session.data(for: req)
        try Self.assertOK(resp, data: data)
    }

    /// Roep een Postgres RPC (stored function) aan via PostgREST.
    func rpc(
        _ function: String,
        params: [String: Any],
        accessToken: String? = nil
    ) async throws {
        let req = try restRequest(
            path: "rpc/\(function)",
            method: "POST",
            accessToken: accessToken,
            body: params,
            prefer: "return=minimal"
        )
        let (data, resp) = try await session.data(for: req)
        try Self.assertOK(resp, data: data)
    }

    // MARK: - Storage

    /// Verwijder een object uit een Supabase Storage bucket.
    func deleteFromStorage(bucket: String, path: String, accessToken: String) async throws {
        guard isConfigured else { throw SupabaseError.missingConfig }
        let encoded = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        guard let endpoint = URL(string: "\(url)/storage/v1/object/\(bucket)/\(encoded)") else { return }
        var req = URLRequest(url: endpoint)
        req.httpMethod = "DELETE"
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, resp) = try await session.data(for: req)
        try Self.assertOK(resp, data: data)
    }

    /// Haal het opslagpad uit een public storage URL voor een gegeven bucket.
    static func storagePath(fromPublicURL urlStr: String, bucket: String) -> String? {
        let marker = "/storage/v1/object/public/\(bucket)/"
        guard let range = urlStr.range(of: marker) else { return nil }
        let raw = String(urlStr[range.upperBound...])
        return raw.removingPercentEncoding ?? raw
    }

    /// Upload raw data naar een Supabase Storage bucket.
    /// Retourneert de public URL van de geüploade file.
    func uploadToStorage(
        bucket: String,
        path: String,
        data: Data,
        contentType: String,
        accessToken: String,
        onProgress: ((Double) -> Void)? = nil
    ) async throws -> String {
        guard isConfigured else { throw SupabaseError.missingConfig }
        let endpoint = URL(string: "\(url)/storage/v1/object/\(bucket)/\(path)")!
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue(contentType, forHTTPHeaderField: "Content-Type")
        req.setValue("*/*", forHTTPHeaderField: "Accept")
        req.httpBody = data

        if let onProgress = onProgress {
            let delegate = UploadProgressDelegate(onProgress: onProgress)
            let progressSession = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
            let (responseData, resp) = try await progressSession.data(for: req)
            try Self.assertOK(resp, data: responseData)
        } else {
            let (responseData, resp) = try await session.data(for: req)
            try Self.assertOK(resp, data: responseData)
        }

        let publicPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        return "\(url)/storage/v1/object/public/\(bucket)/\(publicPath)"
    }

    // MARK: - Helpers

    static func publicStorageURL(bucket: String, path: String) -> String? {
        let publicPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        return "\(SupabaseConfig.url)/storage/v1/object/public/\(bucket)/\(publicPath)"
    }

    static func assertOK(_ resp: URLResponse, data: Data) throws {
        guard let http = resp as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let m = (json["msg"] as? String) ?? (json["message"] as? String) ?? (json["error_description"] as? String) {
                    throw SupabaseError.message(m)
                }
            }
            throw SupabaseError.http(http.statusCode, msg)
        }
    }
}

// MARK: - Upload Progress Delegate

private final class UploadProgressDelegate: NSObject, URLSessionTaskDelegate {
    let onProgress: (Double) -> Void

    init(onProgress: @escaping (Double) -> Void) {
        self.onProgress = onProgress
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard totalBytesExpectedToSend > 0 else { return }
        let fraction = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        Task { @MainActor in
            self.onProgress(fraction)
        }
    }
}
