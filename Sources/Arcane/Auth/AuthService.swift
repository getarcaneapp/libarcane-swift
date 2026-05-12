import Foundation

public struct AuthService: Sendable {
    private let transport: ArcaneURLSessionTransport
    private let authManager: AuthManager
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(transport: ArcaneURLSessionTransport, authManager: AuthManager, decoder: JSONDecoder, encoder: JSONEncoder) {
        self.transport = transport
        self.authManager = authManager
        self.decoder = decoder
        self.encoder = encoder
    }

    @discardableResult
    public func login(username: String, password: String) async throws -> LoginResponse {
        let response: LoginResponse = try await transport.request(
            "auth/login",
            method: "POST",
            body: LoginRequest(password: password, username: username),
            authorized: false
        )
        try await authManager.save(loginResponse: response)
        return response
    }

    public func logout() async throws {
        let _: MessageResponse = try await transport.request("auth/logout", method: "POST", body: Optional<EmptyBody>.none)
        try await authManager.clear()
    }

    public func me() async throws -> User {
        try await transport.request("auth/me")
    }

    @discardableResult
    public func refresh() async throws -> TokenPair {
        try await authManager.refreshTokens()
    }

    // MARK: - OIDC

    // The OIDC endpoints return their response body directly (not wrapped in
    // the standard `{ success, data }` envelope), so we use `rawRequest` and
    // decode the body type ourselves.

    public func oidcStatus() async throws -> OidcStatusInfo {
        let data = try await transport.rawRequest("oidc/status", body: Optional<EmptyBody>.none, authorized: false)
        return try decodeOIDC(OidcStatusInfo.self, from: data)
    }

    public func oidcAuthURL(mobileRedirectURI: String, redirectTo: String = "/") async throws -> OidcAuthUrlResponse {
        let body = OidcAuthUrlRequest(redirectUri: redirectTo, mobileRedirectUri: mobileRedirectURI)
        let data = try await transport.rawRequest("oidc/url", method: "POST", body: body, authorized: false)
        return try decodeOIDC(OidcAuthUrlResponse.self, from: data)
    }

    @discardableResult
    public func oidcCallback(code: String, state: String, mobileRedirectURI: String) async throws -> OidcCallbackResponse {
        let body = OidcCallbackRequest(code: code, state: state, mobileRedirectUri: mobileRedirectURI)
        let data = try await transport.rawRequest("oidc/callback", method: "POST", body: body, authorized: false)
        let response = try decodeOIDC(OidcCallbackResponse.self, from: data)
        let tokens = TokenPair(accessToken: response.token, refreshToken: response.refreshToken, expiresAt: response.expiresAt)
        try await authManager.save(tokens: tokens)
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

struct EmptyBody: Encodable, Sendable {}
