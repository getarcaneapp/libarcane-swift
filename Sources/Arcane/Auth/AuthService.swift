import Foundation

public struct AuthService: Sendable {
  private let transport: ArcaneURLSessionTransport
  private let authManager: AuthManager
  private let decoder: JSONDecoder
  private let encoder: JSONEncoder

  init(
    transport: ArcaneURLSessionTransport, authManager: AuthManager, decoder: JSONDecoder,
    encoder: JSONEncoder
  ) {
    self.transport = transport
    self.authManager = authManager
    self.decoder = decoder
    self.encoder = encoder
  }

  @discardableResult
  public func login(username: String, password: String) async throws -> LoginResponse {
    switch try await authenticate(username: username, password: password) {
    case .authenticated(let response):
      return response
    case .mfaRequired(let challenge):
      throw MFARequiredError(challenge: challenge)
    }
  }

  @discardableResult
  public func authenticate(username: String, password: String) async throws
    -> AuthenticationResult
  {
    let result: AuthenticationResult = try await transport.request(
      "auth/login",
      method: "POST",
      body: LoginRequest(username: username, password: password),
      authorized: false
    )
    try await authManager.save(authenticationResult: result)
    return result
  }

  public func logout() async throws {
    var remoteError: Error?
    do {
      let _: MessageResponse = try await transport.request(
        "auth/logout", method: "POST", body: Optional<EmptyBody>.none)
    } catch {
      remoteError = error
    }

    do {
      try await authManager.clear()
    } catch {
      // Local credential removal is the security-critical outcome. If both
      // operations fail, report this failure rather than the revocation error.
      throw error
    }

    if let remoteError {
      throw remoteError
    }
  }

  public func me() async throws -> User {
    let user: User = try await transport.request("auth/me")
    await authManager.recordCapabilities(from: user)
    return user
  }

  @discardableResult
  public func refresh() async throws -> TokenPair {
    try await authManager.refreshTokens()
  }

  public func changePassword(currentPassword: String?, newPassword: String) async throws {
    let body = PasswordChange(currentPassword: currentPassword, newPassword: newPassword)
    let _: MessageResponse = try await transport.request(
      "auth/password", method: "POST", body: body)
  }

  // MARK: - OIDC

  // The OIDC endpoints return their response body directly (not wrapped in
  // the standard `{ success, data }` envelope), so we use `rawRequest` and
  // decode the body type ourselves.

  public func oidcStatus() async throws -> OIDCStatusInfo {
    let data = try await transport.rawRequest(
      "oidc/status", body: Optional<EmptyBody>.none, authorized: false)
    return try decodeOIDC(OIDCStatusInfo.self, from: data)
  }

  public func oidcConfig() async throws -> OIDCConfigResponse {
    let data = try await transport.rawRequest(
      "oidc/config", body: Optional<EmptyBody>.none, authorized: false)
    return try decodeOIDC(OIDCConfigResponse.self, from: data)
  }

  public func oidcAuthURL(mobileRedirectURI: String, redirectTo: String = "/") async throws
    -> OIDCAuthURLResponse
  {
    let body = OIDCAuthURLRequest(redirectUri: redirectTo, mobileRedirectUri: mobileRedirectURI)
    let data = try await transport.rawRequest(
      "oidc/url", method: "POST", body: body, authorized: false)
    return try decodeOIDC(OIDCAuthURLResponse.self, from: data)
  }

  @discardableResult
  public func oidcCallback(code: String, state: String, mobileRedirectURI: String) async throws
    -> OIDCCallbackResponse
  {
    switch try await authenticateOIDCCallback(
      code: code,
      state: state,
      mobileRedirectURI: mobileRedirectURI
    ) {
    case .authenticated(let response):
      return OIDCCallbackResponse(
        success: true,
        token: response.token,
        refreshToken: response.refreshToken,
        expiresAt: response.expiresAt,
        user: response.user
      )
    case .mfaRequired(let challenge):
      throw MFARequiredError(challenge: challenge)
    }
  }

  @discardableResult
  public func authenticateOIDCCallback(
    code: String,
    state: String,
    mobileRedirectURI: String
  ) async throws -> AuthenticationResult {
    let body = OIDCCallbackRequest(code: code, state: state, mobileRedirectUri: mobileRedirectURI)
    let data = try await transport.rawRequest(
      "oidc/callback", method: "POST", body: body, authorized: false)
    let result = try decodeOIDC(AuthenticationResult.self, from: data)
    try await authManager.save(authenticationResult: result)
    return result
  }

  public func oidcDeviceCode() async throws -> OIDCDeviceAuthResponse {
    let body = OIDCDeviceAuthRequest()
    let data = try await transport.rawRequest(
      "oidc/device/code", method: "POST", body: body, authorized: false)
    return try decodeOIDC(OIDCDeviceAuthResponse.self, from: data)
  }

  @discardableResult
  public func oidcDeviceToken(deviceCode: String) async throws -> OIDCDeviceTokenResponse {
    let body = OIDCDeviceTokenRequest(deviceCode: deviceCode)
    let data = try await transport.rawRequest(
      "oidc/device/token", method: "POST", body: body, authorized: false)
    let response = try decodeOIDC(OIDCDeviceTokenResponse.self, from: data)
    let tokens = TokenPair(
      accessToken: response.token, refreshToken: response.refreshToken,
      expiresAt: response.expiresAt)
    try await authManager.save(tokens: tokens)
    await authManager.recordCapabilities(from: response.user)
    return response
  }

  private func decodeOIDC<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    do {
      return try decoder.decode(type, from: data)
    } catch {
      throw ArcaneError.decoding(String(describing: error))
    }
  }
}
