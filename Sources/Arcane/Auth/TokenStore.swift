import Foundation

public struct TokenPair: Codable, Equatable, Sendable {
    public var accessToken: String
    public var refreshToken: String
    public var expiresAt: Date

    public init(accessToken: String, refreshToken: String, expiresAt: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }
}

public protocol TokenStore: Sendable {
    func loadTokens() async throws -> TokenPair?
    func saveTokens(_ tokens: TokenPair) async throws
    func clearTokens() async throws
}

public actor InMemoryTokenStore: TokenStore {
    private var tokens: TokenPair?

    public init(tokens: TokenPair? = nil) {
        self.tokens = tokens
    }

    public func loadTokens() async throws -> TokenPair? {
        tokens
    }

    public func saveTokens(_ tokens: TokenPair) async throws {
        self.tokens = tokens
    }

    public func clearTokens() async throws {
        tokens = nil
    }
}
