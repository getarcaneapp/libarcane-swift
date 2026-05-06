import Foundation

public struct APIResponse<T: Decodable & Sendable>: Decodable, Sendable {
    public var success: Bool
    public var data: T
}

public struct MessageResponse: Codable, Equatable, Sendable {
    public var message: String
}

public struct LoginRequest: Encodable, Sendable {
    public var username: String
    public var password: String

    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

public struct RefreshRequest: Encodable, Sendable {
    public var refreshToken: String

    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}

public struct LoginResponse: Codable, Sendable {
    public var token: String
    public var refreshToken: String
    public var expiresAt: Date
    public var user: User
}

public struct TokenRefreshResponse: Codable, Equatable, Sendable {
    public var token: String
    public var refreshToken: String
    public var expiresAt: Date
}

public struct User: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var username: String?
    public var email: String?
    public var roles: [String]?
}
