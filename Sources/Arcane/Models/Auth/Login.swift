import Foundation

public struct LoginRequest: Codable, Hashable, Sendable {
    public var username: String
    public var password: String

    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

public struct LoginResponse: Codable, Hashable, Sendable {
    public var token: String
    public var refreshToken: String
    public var expiresAt: Date
    public var user: User

    public init(token: String, refreshToken: String, expiresAt: Date, user: User) {
        self.token = token
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.user = user
    }
}

public struct RefreshRequest: Codable, Hashable, Sendable {
    public var refreshToken: String

    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}

public struct TokenRefreshResponse: Codable, Hashable, Sendable {
    public var token: String
    public var refreshToken: String
    public var expiresAt: Date

    public init(token: String, refreshToken: String, expiresAt: Date) {
        self.token = token
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }
}

public struct PasswordChange: Codable, Hashable, Sendable {
    public var currentPassword: String?
    public var newPassword: String

    public init(currentPassword: String? = nil, newPassword: String) {
        self.currentPassword = currentPassword
        self.newPassword = newPassword
    }
}

public struct AutoLoginConfig: Codable, Hashable, Sendable {
    public var enabled: Bool
    public var username: String

    public init(enabled: Bool, username: String) {
        self.enabled = enabled
        self.username = username
    }
}
