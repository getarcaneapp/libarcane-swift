import Foundation

public struct AuthService: Sendable {
    private let transport: ArcaneURLSessionTransport
    private let authManager: AuthManager

    init(transport: ArcaneURLSessionTransport, authManager: AuthManager) {
        self.transport = transport
        self.authManager = authManager
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
}

struct EmptyBody: Encodable, Sendable {}
