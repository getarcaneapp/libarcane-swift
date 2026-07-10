import Foundation

public actor AuthManager {
  struct AuthenticationContext: Sendable {
    let headers: [String: String]
    let credentialGeneration: UInt64?
  }

  /// Access tokens within this window of expiry are treated as expired and
  /// refreshed proactively. HTTP requests can recover reactively from a 401,
  /// but a WebSocket handshake cannot — a rejected upgrade surfaces as
  /// URLError -1011 with no inspectable status, so the token must be valid
  /// before the request goes out.
  private static let expirySkew: TimeInterval = 45
  /// Minimum spacing between failed proactive refresh attempts, so persistent
  /// clock skew or an offline device doesn't turn every request into a
  /// refresh call.
  private static let failedProactiveRefreshBackoff: TimeInterval = 30

  private let baseURL: URL
  private let tokenStore: any TokenStore
  private let apiKey: String?
  private let urlSession: URLSession
  private let decoder: JSONDecoder
  private let encoder: JSONEncoder
  private var cachedTokens: TokenPair?
  private var refreshTask: Task<TokenPair, Error>?
  private var capabilities: ServerCapabilities = .unknown
  private var lastFailedProactiveRefresh: Date?
  private var credentialGeneration: UInt64 = 0

  public init(
    baseURL: URL,
    tokenStore: any TokenStore,
    apiKey: String?,
    urlSession: URLSession,
    decoder: JSONDecoder,
    encoder: JSONEncoder
  ) {
    self.baseURL = baseURL
    self.tokenStore = tokenStore
    self.apiKey = apiKey
    self.urlSession = urlSession
    self.decoder = decoder
    self.encoder = encoder
  }

  public func authenticationHeaders() async throws -> [String: String] {
    try await authenticationContext().headers
  }

  func authenticationContext() async throws -> AuthenticationContext {
    if let apiKey, !apiKey.isEmpty {
      return AuthenticationContext(headers: ["X-API-Key": apiKey], credentialGeneration: nil)
    }
    if cachedTokens == nil {
      cachedTokens = try await tokenStore.loadTokens()
    }
    if let tokens = cachedTokens,
      !tokens.refreshToken.isEmpty,
      tokens.expiresAt.timeIntervalSinceNow < Self.expirySkew,
      lastFailedProactiveRefresh.map({
        Date().timeIntervalSince($0) > Self.failedProactiveRefreshBackoff
      }) ?? true
    {
      do {
        cachedTokens = try await refreshTokens()
        lastFailedProactiveRefresh = nil
      } catch {
        // Fall back to the existing token: HTTP callers still get the
        // reactive 401 path; a transient refresh failure must not turn an
        // otherwise-valid request into a hard error.
        lastFailedProactiveRefresh = Date()
      }
    }
    guard let accessToken = cachedTokens?.accessToken, !accessToken.isEmpty else {
      return AuthenticationContext(headers: [:], credentialGeneration: nil)
    }
    return AuthenticationContext(
      headers: ["Authorization": "Bearer \(accessToken)"],
      credentialGeneration: credentialGeneration
    )
  }

  public func hasRefreshCredential() async throws -> Bool {
    if apiKey != nil {
      return false
    }
    if cachedTokens == nil {
      cachedTokens = try await tokenStore.loadTokens()
    }
    return !(cachedTokens?.refreshToken.isEmpty ?? true)
  }

  public func save(loginResponse: LoginResponse) async throws {
    let tokens = TokenPair(
      accessToken: loginResponse.token,
      refreshToken: loginResponse.refreshToken,
      expiresAt: loginResponse.expiresAt
    )
    try await save(tokens: tokens)
  }

  public func save(tokens: TokenPair) async throws {
    credentialGeneration &+= 1
    refreshTask?.cancel()
    refreshTask = nil
    cachedTokens = tokens
    try await tokenStore.saveTokens(tokens)
  }

  public func clear() async throws {
    credentialGeneration &+= 1
    refreshTask?.cancel()
    cachedTokens = nil
    refreshTask = nil
    capabilities = .unknown
    try await tokenStore.clearTokens()
  }

  func clear(ifCredentialGenerationMatches generation: UInt64) async throws {
    guard generation == credentialGeneration else { return }
    try await clear()
  }

  public func currentCapabilities() -> ServerCapabilities { capabilities }

  /// Records detected capabilities from a freshly decoded `User`. Ignores
  /// `.unknown` detections so a stale signal never clobbers a known mode.
  public func recordCapabilities(from user: User) {
    let detected = ServerCapabilities.detect(from: user)
    guard detected != .unknown else { return }
    capabilities = ServerCapabilities(mode: detected)
  }

  public func refreshTokens() async throws -> TokenPair {
    try await refreshTokens(isRetry: false)
  }

  private func refreshTokens(isRetry: Bool) async throws -> TokenPair {
    if let refreshTask {
      return try await refreshTask.value
    }
    // The store, not the in-memory cache, is the source of truth going into
    // a refresh: another process sharing the token store (widget/intents
    // extension) may have rotated the pair while this process was suspended,
    // and the server invalidates the old refresh token immediately.
    if let stored = try? await tokenStore.loadTokens() {
      cachedTokens = stored
    } else if cachedTokens == nil {
      cachedTokens = try await tokenStore.loadTokens()
    }
    if let refreshTask {
      return try await refreshTask.value
    }
    guard let refreshToken = cachedTokens?.refreshToken, !refreshToken.isEmpty else {
      throw ArcaneError.unauthorized
    }
    let generation = credentialGeneration

    let task = Task<TokenPair, Error> {
      try await performRefreshAndPersist(
        refreshToken: refreshToken,
        credentialGeneration: generation
      )
    }

    refreshTask = task
    do {
      let tokens = try await task.value
      if generation == credentialGeneration {
        refreshTask = nil
      }
      return tokens
    } catch {
      if generation == credentialGeneration {
        refreshTask = nil
      }
      if error is CancellationError || generation != credentialGeneration {
        throw CancellationError()
      }
      return try await handleRefreshFailure(
        error,
        rejectedRefreshToken: refreshToken,
        isRetry: isRetry
      )
    }
  }

  private func handleRefreshFailure(
    _ error: Error,
    rejectedRefreshToken: String,
    isRetry: Bool
  ) async throws -> TokenPair {
    // Only discard the stored credential when the server explicitly rejects
    // the refresh token. Transient failures must retain it for a later retry.
    guard error as? ArcaneError == .unauthorized || error as? ArcaneError == .forbidden else {
      throw error
    }

    // A second process may have won the single-use rotation race.
    if !isRetry,
      let latest = try? await tokenStore.loadTokens(),
      !latest.refreshToken.isEmpty,
      latest.refreshToken != rejectedRefreshToken
    {
      cachedTokens = latest
      return try await refreshTokens(isRetry: true)
    }

    // An unreadable store must never cost the user their session.
    if let current = try? await tokenStore.loadTokens(),
      current.refreshToken == rejectedRefreshToken
    {
      try? await clear()
    }
    throw error
  }

  private func performRefreshAndPersist(
    refreshToken: String,
    credentialGeneration generation: UInt64
  ) async throws -> TokenPair {
    let tokens = try await performRefreshRequest(refreshToken: refreshToken)
    try Task.checkCancellation()
    guard generation == credentialGeneration else {
      throw CancellationError()
    }

    try await tokenStore.saveTokens(tokens)
    try Task.checkCancellation()
    guard generation == credentialGeneration else {
      // A clear/save may have won while the token-store write was suspended.
      // Remove only our stale refresh result; never delete a newer login.
      if let current = try? await tokenStore.loadTokens(), current == tokens {
        try? await tokenStore.clearTokens()
      }
      throw CancellationError()
    }

    cachedTokens = tokens
    return tokens
  }

  private func performRefreshRequest(refreshToken: String) async throws -> TokenPair {
    var request = URLRequest(url: baseURL.appendingAPIPath("auth/refresh"))
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.httpBody = try encoder.encode(RefreshRequest(refreshToken: refreshToken))

    do {
      let (data, response) = try await urlSession.data(for: request)
      guard let http = response as? HTTPURLResponse else {
        throw ArcaneError.transport("Refresh did not return an HTTP response")
      }
      guard (200..<300).contains(http.statusCode) else {
        throw ArcaneError.from(
          statusCode: http.statusCode, data: data, headers: http.allHeaderFields, decoder: decoder)
      }
      let envelope = try decoder.decode(APIResponse<TokenRefreshResponse>.self, from: data)
      let refreshResponse = envelope.data
      return TokenPair(
        accessToken: refreshResponse.token,
        refreshToken: refreshResponse.refreshToken,
        expiresAt: refreshResponse.expiresAt
      )
    } catch let error as ArcaneError {
      throw error
    } catch let error as URLError {
      throw normalizedTransportError(error)
    } catch {
      throw ArcaneError.decoding(String(describing: error))
    }
  }
}
