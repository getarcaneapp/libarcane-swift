import Foundation

public struct User: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var username: String
    public var displayName: String?
    public var email: String?
    public var roles: [String]
    public var canDelete: Bool
    public var oidcSubjectId: String?
    public var locale: String?
    public var createdAt: String?
    public var updatedAt: String?
    public var requiresPasswordChange: Bool

    public init(
        id: String,
        username: String,
        displayName: String? = nil,
        email: String? = nil,
        roles: [String] = [],
        canDelete: Bool = false,
        oidcSubjectId: String? = nil,
        locale: String? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        requiresPasswordChange: Bool = false
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.email = email
        self.roles = roles
        self.canDelete = canDelete
        self.oidcSubjectId = oidcSubjectId
        self.locale = locale
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.requiresPasswordChange = requiresPasswordChange
    }
}

public struct CreateUser: Codable, Hashable, Sendable {
    public var username: String
    public var password: String
    public var displayName: String?
    public var email: String?
    public var roles: [String]?
    public var locale: String?

    public init(
        username: String,
        password: String,
        displayName: String? = nil,
        email: String? = nil,
        roles: [String]? = nil,
        locale: String? = nil
    ) {
        self.username = username
        self.password = password
        self.displayName = displayName
        self.email = email
        self.roles = roles
        self.locale = locale
    }
}

public struct UpdateUser: Codable, Hashable, Sendable {
    public var username: String?
    public var displayName: String?
    public var email: String?
    public var roles: [String]?
    public var locale: String?
    public var password: String?

    public init(
        username: String? = nil,
        displayName: String? = nil,
        email: String? = nil,
        roles: [String]? = nil,
        locale: String? = nil,
        password: String? = nil
    ) {
        self.username = username
        self.displayName = displayName
        self.email = email
        self.roles = roles
        self.locale = locale
        self.password = password
    }
}
