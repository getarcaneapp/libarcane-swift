import Foundation

public final class ArcaneURLSessionTransport: @unchecked Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let authManager: AuthManager
    private let retryPolicy: RetryPolicy
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        baseURL: URL,
        session: URLSession,
        authManager: AuthManager,
        retryPolicy: RetryPolicy,
        decoder: JSONDecoder,
        encoder: JSONEncoder
    ) {
        self.baseURL = baseURL
        self.session = session
        self.authManager = authManager
        self.retryPolicy = retryPolicy
        self.decoder = decoder
        self.encoder = encoder
    }

    public func request<T: Decodable & Sendable, Body: Encodable & Sendable>(
        _ path: String,
        method: String = "GET",
        query: [URLQueryItem] = [],
        body: Body? = nil,
        authorized: Bool = true
    ) async throws -> T {
        let data = try await rawRequest(path, method: method, query: query, body: body, authorized: authorized)
        do {
            return try decoder.decode(APIResponse<T>.self, from: data).data
        } catch {
            throw ArcaneError.decoding(String(describing: error))
        }
    }

    public func request<T: Decodable & Sendable>(
        _ path: String,
        method: String = "GET",
        query: [URLQueryItem] = [],
        authorized: Bool = true
    ) async throws -> T {
        let body: EmptyBody? = nil
        return try await request(path, method: method, query: query, body: body, authorized: authorized)
    }

    public func paginated<T: Decodable & Sendable>(
        _ path: String,
        page: Int,
        pageSize: Int,
        query: [URLQueryItem] = []
    ) async throws -> PaginatedResponse<T> {
        var items = query
        items.append(URLQueryItem(name: "page", value: "\(page)"))
        items.append(URLQueryItem(name: "itemsPerPage", value: "\(pageSize)"))
        let data = try await rawRequest(path, query: items, body: Optional<EmptyBody>.none, authorized: true)
        do {
            return try decoder.decode(PaginatedResponse<T>.self, from: data)
        } catch {
            throw ArcaneError.decoding(String(describing: error))
        }
    }

    public func rawRequest<Body: Encodable & Sendable>(
        _ path: String,
        method: String = "GET",
        query: [URLQueryItem] = [],
        body: Body? = nil,
        authorized: Bool = true
    ) async throws -> Data {
        var didRefresh = false
        var attempt = 1

        while true {
            let request = try await makeRequest(path, method: method, query: query, body: body, authorized: authorized)
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw ArcaneError.transport("Request did not return an HTTP response")
                }

                if http.statusCode == 401, authorized, !didRefresh, try await authManager.hasRefreshCredential() {
                    _ = try await authManager.refreshTokens()
                    didRefresh = true
                    continue
                }

                if shouldRetry(method: method, statusCode: http.statusCode), attempt < retryPolicy.maxAttempts {
                    try await sleepBeforeRetry(attempt: attempt)
                    attempt += 1
                    continue
                }

                guard (200..<300).contains(http.statusCode) else {
                    if http.statusCode == 401 {
                        try? await authManager.clear()
                    }
                    throw ArcaneError.from(statusCode: http.statusCode, data: data, headers: http.allHeaderFields, decoder: decoder)
                }
                return data
            } catch let error as ArcaneError {
                throw error
            } catch let error as URLError {
                if shouldRetry(method: method, error: error), attempt < retryPolicy.maxAttempts {
                    try await sleepBeforeRetry(attempt: attempt)
                    attempt += 1
                    continue
                }
                throw ArcaneError.transport(error.localizedDescription)
            }
        }
    }

    public func websocketRequest(path: String, query: [URLQueryItem] = []) async throws -> URLRequest {
        var request = URLRequest(url: baseURL.appendingAPIPath(path).withQueryItems(query).webSocketURL())
        for (key, value) in try await authManager.authenticationHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }
        return request
    }

    private func makeRequest<Body: Encodable & Sendable>(
        _ path: String,
        method: String,
        query: [URLQueryItem],
        body: Body?,
        authorized: Bool
    ) async throws -> URLRequest {
        var request = URLRequest(url: baseURL.appendingAPIPath(path).withQueryItems(query))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if authorized {
            for (key, value) in try await authManager.authenticationHeaders() {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }
        return request
    }

    private func shouldRetry(method: String, statusCode: Int) -> Bool {
        guard ["GET", "HEAD", "OPTIONS", "PUT", "DELETE"].contains(method.uppercased()) else {
            return false
        }
        return [429, 502, 503, 504].contains(statusCode)
    }

    private func shouldRetry(method: String, error: URLError) -> Bool {
        guard ["GET", "HEAD", "OPTIONS", "PUT", "DELETE"].contains(method.uppercased()) else {
            return false
        }
        return error.code != .cancelled
    }

    private func sleepBeforeRetry(attempt: Int) async throws {
        let multiplier = 1 << max(0, attempt - 1)
        let base = retryPolicy.baseBackoff.components.attoseconds / 1_000_000_000
            + retryPolicy.baseBackoff.components.seconds * 1_000_000_000
        let maxDelay = retryPolicy.maxBackoff.components.attoseconds / 1_000_000_000
            + retryPolicy.maxBackoff.components.seconds * 1_000_000_000
        let delay = min(base * Int64(multiplier), maxDelay)
        try await Task.sleep(nanoseconds: UInt64(max(delay, 0)))
    }
}

extension URL {
    func appendingAPIPath(_ path: String) -> URL {
        let normalizedBase = absoluteString.hasSuffix("/") ? self : appendingPathComponent("")
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if normalizedBase.path.hasSuffix("/api") || normalizedBase.path.hasSuffix("/api/") {
            return normalizedBase.appendingPathComponent(trimmed)
        }
        return normalizedBase.appendingPathComponent("api").appendingPathComponent(trimmed)
    }

    func withQueryItems(_ queryItems: [URLQueryItem]) -> URL {
        guard !queryItems.isEmpty, var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        components.queryItems = (components.queryItems ?? []) + queryItems
        return components.url ?? self
    }

    func webSocketURL() -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        if components.scheme == "https" {
            components.scheme = "wss"
        } else if components.scheme == "http" {
            components.scheme = "ws"
        }
        return components.url ?? self
    }
}
