import Foundation

public final class ArcaneURLSessionTransport: Sendable {
  struct AuthenticatedRequest: Sendable {
    let request: URLRequest
    let credentialGeneration: UInt64?
  }

  let baseURL: URL
  let session: URLSession
  let authManager: AuthManager
  let retryPolicy: RetryPolicy
  let decoder: JSONDecoder
  let encoder: JSONEncoder
  let proxySupport: ProxyRequestSupport
  let defaultRequestOptions: ArcaneRequestOptions

  init(
    baseURL: URL,
    session: URLSession,
    authManager: AuthManager,
    retryPolicy: RetryPolicy,
    decoder: JSONDecoder,
    encoder: JSONEncoder,
    additionalHeaders: [String: String] = [:],
    proxySession: (any ArcaneProxySession)? = nil,
    defaultRequestOptions: ArcaneRequestOptions = .init()
  ) {
    self.baseURL = baseURL
    self.session = session
    self.authManager = authManager
    self.retryPolicy = retryPolicy
    self.decoder = decoder
    self.encoder = encoder
    self.defaultRequestOptions = defaultRequestOptions
    self.proxySupport = ProxyRequestSupport(
      baseURL: baseURL,
      additionalHeaders: additionalHeaders,
      session: proxySession
    )
  }

  @concurrent
  public func request<T: Decodable & Sendable, Body: Encodable & Sendable>(
    _ path: String,
    method: String = "GET",
    query: [URLQueryItem] = [],
    body: Body? = nil,
    authorized: Bool = true,
    options: ArcaneRequestOptions? = nil
  ) async throws -> T {
    let data = try await rawRequest(
      path,
      method: method,
      query: query,
      body: body,
      authorized: authorized,
      options: options
    )
    do {
      return try decoder.decode(APIResponse<T>.self, from: data).data
    } catch {
      throw ArcaneError.decoding(String(describing: error))
    }
  }

  @concurrent
  public func request<T: Decodable & Sendable>(
    _ path: String,
    method: String = "GET",
    query: [URLQueryItem] = [],
    authorized: Bool = true,
    options: ArcaneRequestOptions? = nil
  ) async throws -> T {
    let body: EmptyBody? = nil
    return try await request(
      path,
      method: method,
      query: query,
      body: body,
      authorized: authorized,
      options: options
    )
  }

  @concurrent
  public func paginated<T: Decodable & Sendable>(
    _ path: String,
    start: Int,
    limit: Int,
    query: [URLQueryItem] = [],
    options: ArcaneRequestOptions? = nil
  ) async throws -> PaginatedResponse<T> {
    var items = query
    items.append(URLQueryItem(name: "start", value: "\(max(0, start))"))
    items.append(URLQueryItem(name: "limit", value: "\(limit)"))
    let data = try await rawRequest(
      path,
      query: items,
      body: Optional<EmptyBody>.none,
      authorized: true,
      options: options
    )
    do {
      return try decoder.decode(PaginatedResponse<T>.self, from: data)
    } catch {
      throw ArcaneError.decoding(String(describing: error))
    }
  }

  @concurrent
  public func rawRequest<Body: Encodable & Sendable>(
    _ path: String,
    method: String = "GET",
    query: [URLQueryItem] = [],
    body: Body? = nil,
    authorized: Bool = true,
    options: ArcaneRequestOptions? = nil
  ) async throws -> Data {
    try await rawDataRequest(
      path,
      method: method,
      query: query,
      body: try body.map { try encoder.encode($0) },
      contentType: "application/json",
      authorized: authorized,
      options: options,
      expectsJSONResponse: true
    )
  }

  /// Sends already encoded bytes through the standard authentication and retry handling.
  @concurrent
  public func rawDataRequest(
    _ path: String,
    method: String = "PUT",
    query: [URLQueryItem] = [],
    body: Data?,
    contentType: String = "application/octet-stream",
    authorized: Bool = true,
    options: ArcaneRequestOptions? = nil,
    expectsJSONResponse: Bool = false
  ) async throws -> Data {
    var didRefresh = false
    var attempt = 1
    let requestOptions = resolvedRequestOptions(options)

    while true {
      var request = makeRequest(path, method: method, query: query, body: body, contentType: contentType)
      applyRequestOptions(to: &request, options: requestOptions)
      let generation = try await applyAuthenticationHeaders(to: &request, authorized: authorized)
      do {
        let proxyDelegate = try await proxySupport.prepare(&request)
        let (data, response) = try await session.data(for: request, delegate: proxyDelegate)
        guard let http = response as? HTTPURLResponse else {
          throw ArcaneError.transport("Request did not return an HTTP response")
        }

        await proxyDelegate.receive(http)
        try proxySupport.check(http, data: data, expectsJSON: expectsJSONResponse)

        if try await refreshAuthorizationIfNeeded(
          statusCode: http.statusCode,
          authorized: authorized,
          didRefresh: &didRefresh,
          sentAuthorization: request.value(forHTTPHeaderField: "Authorization")
        ) {
          continue
        }

        if shouldRetry(method: method, statusCode: http.statusCode),
          attempt < retryPolicy.maxAttempts {
          try await sleepBeforeRetry(attempt: attempt)
          attempt += 1
          continue
        }

        guard (200..<300).contains(http.statusCode) else {
          if http.statusCode == 401, let generation {
            try? await authManager.clear(ifCredentialGenerationMatches: generation)
          }
          throw ArcaneError.from(
            statusCode: http.statusCode,
            data: data,
            headers: http.allHeaderFields,
            decoder: decoder
          )
        }
        return data
      } catch let error as ArcaneError {
        throw error
      } catch is CancellationError {
        throw CancellationError()
      } catch let error as URLError {
        if shouldRetry(method: method, error: error), attempt < retryPolicy.maxAttempts {
          try await sleepBeforeRetry(attempt: attempt)
          attempt += 1
          continue
        }
        throw normalizedTransportError(error)
      }
    }
  }

  @concurrent
  public func websocketRequest(
    path: String,
    query: [URLQueryItem] = [],
    options: ArcaneRequestOptions? = nil
  ) async throws -> URLRequest {
    var request = URLRequest(
      url: baseURL.appendingAPIPath(path).withQueryItems(query).webSocketURL()
    )
    applyRequestOptions(to: &request, options: resolvedRequestOptions(options))
    _ = try await applyAuthenticationHeaders(to: &request)
    _ = try await proxySupport.prepare(&request)
    return request
  }

  /// Creates an unresumed WebSocket task with scoped proxy credentials and redirects.
  @concurrent
  public func makeWebSocketTask(
    path: String,
    query: [URLQueryItem] = [],
    options: ArcaneRequestOptions? = nil
  ) async throws -> URLSessionWebSocketTask {
    var request = try await websocketRequest(path: path, query: query, options: options)
    let delegate = try await proxySupport.prepare(&request)
    let task = session.webSocketTask(with: request)
    task.delegate = delegate
    return task
  }

  /// Returns the raw bytes of a `GET` response. Used for binary downloads
  /// (mTLS bundles, volume backups, file contents). The auth/retry path is
  /// the same as `rawRequest` but the result is unwrapped binary instead of
  /// an `APIResponse<T>` envelope.
  @concurrent
  public func downloadRaw(
    _ path: String,
    query: [URLQueryItem] = [],
    authorized: Bool = true,
    options: ArcaneRequestOptions? = nil
  ) async throws -> Data {
    try await rawDataRequest(
      path,
      method: "GET",
      query: query,
      body: nil,
      authorized: authorized,
      options: options
    )
  }

  private func makeRequest(
    _ path: String,
    method: String,
    query: [URLQueryItem],
    body: Data?,
    contentType: String
  ) -> URLRequest {
    var request = URLRequest(url: baseURL.appendingAPIPath(path).withQueryItems(query))
    request.httpMethod = method
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    if let body {
      request.setValue(contentType, forHTTPHeaderField: "Content-Type")
      request.httpBody = body
    }
    return request
  }

  @discardableResult
  func applyAuthenticationHeaders(
    to request: inout URLRequest,
    authorized: Bool = true
  ) async throws -> UInt64? {
    guard authorized else {
      return nil
    }
    let context = try await authManager.authenticationContext()
    for (key, value) in context.headers {
      request.setValue(value, forHTTPHeaderField: key)
    }
    return context.headers["Authorization"] == nil ? nil : context.credentialGeneration
  }

  func checkStreamResponse(_ response: HTTPURLResponse, bytes: URLSession.AsyncBytes, expectsJSON: Bool = true) async throws {
    try proxySupport.check(response, expectsJSON: expectsJSON)
    if [401, 403].contains(response.statusCode) {
      var data = Data()
      for try await byte in bytes {
        data.append(byte)
        if data.count >= 4096 { break }
      }
      try proxySupport.check(response, data: data)
    }
  }

  func refreshAuthorizationIfNeeded(
    statusCode: Int,
    authorized: Bool,
    didRefresh: inout Bool,
    sentAuthorization: String? = nil
  ) async throws -> Bool {
    guard statusCode == 401,
      authorized,
      !didRefresh,
      try await authManager.hasRefreshCredential()
    else {
      return false
    }
    // A refresh finished while this request was in flight: retry with the
    // rotated token instead of spending another single-use refresh token.
    if let sentAuthorization,
      let current = await authManager.currentAuthorizationHeader(),
      current != sentAuthorization {
      didRefresh = true
      return true
    }
    _ = try await authManager.refreshTokens()
    didRefresh = true
    return true
  }

  func makeMultipartRequest(
    path: String,
    method: String,
    query: [URLQueryItem],
    prepared: PreparedMultipart,
    accept: String,
    options: ArcaneRequestOptions? = nil
  ) async throws -> AuthenticatedRequest {
    var request = URLRequest(url: baseURL.appendingAPIPath(path).withQueryItems(query))
    request.httpMethod = method
    request.setValue(accept, forHTTPHeaderField: "Accept")
    request.setValue(
      "multipart/form-data; boundary=\(prepared.boundary)",
      forHTTPHeaderField: "Content-Type"
    )
    applyRequestOptions(to: &request, options: resolvedRequestOptions(options))
    let generation = try await applyAuthenticationHeaders(to: &request)
    return AuthenticatedRequest(request: request, credentialGeneration: generation)
  }

  func withRequestOptions(_ options: ArcaneRequestOptions) -> ArcaneURLSessionTransport {
    ArcaneURLSessionTransport(
      baseURL: baseURL,
      session: session,
      authManager: authManager,
      retryPolicy: retryPolicy,
      decoder: decoder,
      encoder: encoder,
      additionalHeaders: proxySupport.additionalHeaders,
      proxySession: proxySupport.session,
      defaultRequestOptions: options
    )
  }

  func resolvedRequestOptions(_ options: ArcaneRequestOptions?) -> ArcaneRequestOptions {
    options ?? defaultRequestOptions
  }

  func applyRequestOptions(
    to request: inout URLRequest,
    options: ArcaneRequestOptions
  ) {
    if let activityBatchID = options.activityBatchID {
      request.setValue(activityBatchID, forHTTPHeaderField: "X-Arcane-Batch-Id")
    }
    if let stepUpToken = options.stepUpToken {
      request.setValue(stepUpToken, forHTTPHeaderField: "X-Step-Up-Token")
    }
  }

  func shouldRetry(method: String, statusCode: Int) -> Bool {
    guard ["GET", "HEAD", "OPTIONS", "PUT", "DELETE"].contains(method.uppercased()) else {
      return false
    }
    return [429, 502, 503, 504].contains(statusCode)
  }

  func shouldRetry(method: String, error: URLError) -> Bool {
    guard ["GET", "HEAD", "OPTIONS", "PUT", "DELETE"].contains(method.uppercased()) else {
      return false
    }
    switch error.code {
    // Retrying these can't succeed and only delays the error: an unreachable
    // or timed-out host already waited out its timeout, and TLS/trust or
    // malformed-response failures repeat identically.
    case .cancelled, .timedOut, .notConnectedToInternet, .badServerResponse,
      .secureConnectionFailed, .serverCertificateUntrusted, .serverCertificateHasBadDate,
      .serverCertificateHasUnknownRoot, .serverCertificateNotYetValid,
      .clientCertificateRejected, .clientCertificateRequired,
      .appTransportSecurityRequiresSecureConnection, .userAuthenticationRequired:
      return false
    default:
      return true
    }
  }

  func sleepBeforeRetry(attempt: Int) async throws {
    try await Task.sleep(for: retryDelay(attempt: attempt))
  }

  func retryDelay(attempt: Int) -> Duration {
    let cap = max(.zero, retryPolicy.maxBackoff)
    var delay = min(max(.zero, retryPolicy.baseBackoff), cap)
    guard delay > .zero, attempt > 1 else { return delay }
    // Stop at the cap before multiplying, including for arbitrarily large attempt counts.
    for _ in 1..<attempt {
      guard delay < cap else { break }
      if delay >= cap - delay { return cap }
      delay *= 2
    }
    return delay
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
    guard !queryItems.isEmpty,
      var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
    else {
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
