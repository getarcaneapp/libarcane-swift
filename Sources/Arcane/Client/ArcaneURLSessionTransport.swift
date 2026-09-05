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
  let defaultRequestOptions: ArcaneRequestOptions

  init(
    baseURL: URL,
    session: URLSession,
    authManager: AuthManager,
    retryPolicy: RetryPolicy,
    decoder: JSONDecoder,
    encoder: JSONEncoder,
    defaultRequestOptions: ArcaneRequestOptions = .init()
  ) {
    self.baseURL = baseURL
    self.session = session
    self.authManager = authManager
    self.retryPolicy = retryPolicy
    self.decoder = decoder
    self.encoder = encoder
    self.defaultRequestOptions = defaultRequestOptions
  }

  public func request<T: Decodable & Sendable, Body: Encodable & Sendable>(
    _ path: String,
    method: String = "GET",
    query: [URLQueryItem] = [],
    body: Body? = nil,
    authorized: Bool = true,
    options: ArcaneRequestOptions? = nil
  ) async throws -> T {
    let data = try await rawRequest(
      path, method: method, query: query, body: body, authorized: authorized, options: options)
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
    authorized: Bool = true,
    options: ArcaneRequestOptions? = nil
  ) async throws -> T {
    let body: EmptyBody? = nil
    return try await request(
      path, method: method, query: query, body: body, authorized: authorized, options: options)
  }

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
      path, query: items, body: Optional<EmptyBody>.none, authorized: true, options: options)
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
    authorized: Bool = true,
    options: ArcaneRequestOptions? = nil
  ) async throws -> Data {
    try await rawDataRequest(
      path, method: method, query: query,
      body: try body.map { try encoder.encode($0) }, contentType: "application/json",
      authorized: authorized, options: options)
  }

  /// Sends already encoded bytes through the standard authentication and retry handling.
  public func rawDataRequest(
    _ path: String,
    method: String = "PUT",
    query: [URLQueryItem] = [],
    body: Data?,
    contentType: String = "application/octet-stream",
    authorized: Bool = true,
    options: ArcaneRequestOptions? = nil
  ) async throws -> Data {
    var didRefresh = false
    var attempt = 1
    let requestOptions = resolvedRequestOptions(options)

    while true {
      let prepared = try await makeRequest(
        path,
        method: method,
        query: query,
        body: body,
        contentType: contentType,
        authorized: authorized,
        options: requestOptions)
      do {
        let (data, response) = try await session.data(for: prepared.request)
        guard let http = response as? HTTPURLResponse else {
          throw ArcaneError.transport("Request did not return an HTTP response")
        }

        if try await refreshAuthorizationIfNeeded(
          statusCode: http.statusCode,
          authorized: authorized,
          didRefresh: &didRefresh
        ) {
          continue
        }

        if shouldRetry(method: method, statusCode: http.statusCode),
          attempt < retryPolicy.maxAttempts
        {
          try await sleepBeforeRetry(attempt: attempt)
          attempt += 1
          continue
        }

        guard (200..<300).contains(http.statusCode) else {
          if http.statusCode == 401, let generation = prepared.credentialGeneration {
            try? await authManager.clear(ifCredentialGenerationMatches: generation)
          }
          throw ArcaneError.from(
            statusCode: http.statusCode, data: data, headers: http.allHeaderFields, decoder: decoder
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

  public func websocketRequest(
    path: String,
    query: [URLQueryItem] = [],
    options: ArcaneRequestOptions? = nil
  ) async throws -> URLRequest {
    var request = URLRequest(
      url: baseURL.appendingAPIPath(path).withQueryItems(query).webSocketURL())
    applyRequestOptions(to: &request, options: resolvedRequestOptions(options))
    _ = try await applyAuthenticationHeaders(to: &request)
    return request
  }

  /// Returns the bytes of an HTTP response as an async sequence, plus the response
  /// metadata. Used by NDJSON streams and binary downloads. The caller is responsible
  /// for checking `http.statusCode` and consuming the bytes — this method does not
  /// validate the response status.
  public func byteStream(
    path: String,
    method: String = "GET",
    query: [URLQueryItem] = [],
    body: Data? = nil,
    contentType: String? = nil,
    accept: String = "application/x-ndjson, application/x-json-stream, application/json",
    authorized: Bool = true,
    options: ArcaneRequestOptions? = nil
  ) async throws -> (URLSession.AsyncBytes, HTTPURLResponse) {
    var didRefresh = false
    let requestOptions = resolvedRequestOptions(options)
    while true {
      var request = URLRequest(url: baseURL.appendingAPIPath(path).withQueryItems(query))
      request.httpMethod = method
      request.setValue(accept, forHTTPHeaderField: "Accept")
      applyRequestOptions(to: &request, options: requestOptions)
      let generation = try await applyAuthenticationHeaders(to: &request, authorized: authorized)
      if let body {
        if let contentType {
          request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        request.httpBody = body
      }
      let (bytes, response): (URLSession.AsyncBytes, URLResponse)
      do {
        (bytes, response) = try await session.bytes(for: request)
      } catch {
        throw normalizedTransportError(error)
      }
      guard let http = response as? HTTPURLResponse else {
        throw ArcaneError.transport("Request did not return an HTTP response")
      }
      if try await refreshAuthorizationIfNeeded(
        statusCode: http.statusCode,
        authorized: authorized,
        didRefresh: &didRefresh
      ) {
        continue
      }
      if http.statusCode == 401, let generation {
        try? await authManager.clear(ifCredentialGenerationMatches: generation)
      }
      return (bytes, http)
    }
  }

  /// Uploads a multipart/form-data request from a tempfile (streamed from disk to
  /// avoid loading large files into memory). The response is decoded as the
  /// standard `APIResponse<T>` envelope.
  public func multipartUpload<T: Decodable & Sendable>(
    _ path: String,
    method: String = "POST",
    query: [URLQueryItem] = [],
    fields: [String: String] = [:],
    files: [MultipartFile],
    options: ArcaneRequestOptions? = nil
  ) async throws -> T {
    let prepared = try makeMultipartTempFile(fields: fields, files: files)
    defer { try? FileManager.default.removeItem(at: prepared.url) }

    var didRefresh = false
    let requestOptions = resolvedRequestOptions(options)
    while true {
      let preparedRequest = try await makeMultipartRequest(
        path: path,
        method: method,
        query: query,
        prepared: prepared,
        accept: "application/json",
        options: requestOptions
      )
      let (data, response): (Data, URLResponse)
      do {
        (data, response) = try await session.upload(
          for: preparedRequest.request,
          fromFile: prepared.url
        )
      } catch {
        throw normalizedTransportError(error)
      }
      guard let http = response as? HTTPURLResponse else {
        throw ArcaneError.transport("Upload did not return an HTTP response")
      }
      if try await refreshAuthorizationIfNeeded(
        statusCode: http.statusCode,
        authorized: true,
        didRefresh: &didRefresh
      ) {
        continue
      }
      guard (200..<300).contains(http.statusCode) else {
        if http.statusCode == 401, let generation = preparedRequest.credentialGeneration {
          try? await authManager.clear(ifCredentialGenerationMatches: generation)
        }
        throw ArcaneError.from(
          statusCode: http.statusCode, data: data, headers: http.allHeaderFields, decoder: decoder)
      }
      do {
        return try decoder.decode(APIResponse<T>.self, from: data).data
      } catch {
        throw ArcaneError.decoding(String(describing: error))
      }
    }
  }

  /// Uploads a multipart/form-data request to an endpoint that returns NDJSON.
  public func multipartUploadStream<Element: Decodable & Sendable>(
    _ path: String,
    method: String = "POST",
    query: [URLQueryItem] = [],
    fields: [String: String] = [:],
    files: [MultipartFile],
    options: ArcaneRequestOptions? = nil
  ) -> NDJSONStream<Element> {
    // The actual upload and streaming happen lazily inside the AsyncSequence's
    // iterator so the caller can `for try await` directly. The body is the
    // assembled multipart tempfile; the stream owns the tempfile lifecycle.
    let endpoint = MultipartEndpoint(
      path: path, method: method, query: query, fields: fields, files: files)
    let streamTransport = options.map(withRequestOptions) ?? self
    return NDJSONStream(transport: streamTransport, multipart: endpoint)
  }

  /// Returns the raw bytes of a `GET` response. Used for binary downloads
  /// (mTLS bundles, volume backups, file contents). The auth/retry path is
  /// the same as `rawRequest` but the result is unwrapped binary instead of
  /// an `APIResponse<T>` envelope.
  public func downloadRaw(
    _ path: String,
    query: [URLQueryItem] = [],
    authorized: Bool = true,
    options: ArcaneRequestOptions? = nil
  ) async throws -> Data {
    try await rawRequest(
      path,
      query: query,
      body: Optional<EmptyBody>.none,
      authorized: authorized,
      options: options)
  }

  private func makeRequest(
    _ path: String,
    method: String,
    query: [URLQueryItem],
    body: Data?,
    contentType: String,
    authorized: Bool,
    options: ArcaneRequestOptions
  ) async throws -> AuthenticatedRequest {
    var request = URLRequest(url: baseURL.appendingAPIPath(path).withQueryItems(query))
    request.httpMethod = method
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    applyRequestOptions(to: &request, options: options)
    let generation = try await applyAuthenticationHeaders(to: &request, authorized: authorized)
    if let body {
      request.setValue(contentType, forHTTPHeaderField: "Content-Type")
      request.httpBody = body
    }
    return AuthenticatedRequest(request: request, credentialGeneration: generation)
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

  func refreshAuthorizationIfNeeded(
    statusCode: Int,
    authorized: Bool,
    didRefresh: inout Bool
  ) async throws -> Bool {
    guard statusCode == 401,
      authorized,
      !didRefresh,
      try await authManager.hasRefreshCredential()
    else {
      return false
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
    return error.code != .cancelled
  }

  func sleepBeforeRetry(attempt: Int) async throws {
    let multiplier = 1 << max(0, attempt - 1)
    let base =
      retryPolicy.baseBackoff.components.attoseconds / 1_000_000_000
      + retryPolicy.baseBackoff.components.seconds * 1_000_000_000
    let maxDelay =
      retryPolicy.maxBackoff.components.attoseconds / 1_000_000_000
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
