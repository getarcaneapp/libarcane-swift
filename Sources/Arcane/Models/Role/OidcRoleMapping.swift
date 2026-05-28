import Foundation

public enum OidcRoleMappingSource: String, Codable, Hashable, Sendable {
    case manual
    case env
}

public struct OidcRoleMapping: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var claimValue: String
    public var roleId: String
    public var environmentId: String?
    public var source: String
    public var createdAt: Date
    public var updatedAt: Date?

    public init(
        id: String,
        claimValue: String,
        roleId: String,
        environmentId: String? = nil,
        source: String = OidcRoleMappingSource.manual.rawValue,
        createdAt: Date,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.claimValue = claimValue
        self.roleId = roleId
        self.environmentId = environmentId
        self.source = source
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var sourceKind: OidcRoleMappingSource? { OidcRoleMappingSource(rawValue: source) }
}

public struct CreateOidcRoleMapping: Codable, Hashable, Sendable {
    public var claimValue: String
    public var roleId: String
    public var environmentId: String?

    public init(claimValue: String, roleId: String, environmentId: String? = nil) {
        self.claimValue = claimValue
        self.roleId = roleId
        self.environmentId = environmentId
    }
}

public struct UpdateOidcRoleMapping: Codable, Hashable, Sendable {
    public var claimValue: String
    public var roleId: String
    public var environmentId: String?

    public init(claimValue: String, roleId: String, environmentId: String? = nil) {
        self.claimValue = claimValue
        self.roleId = roleId
        self.environmentId = environmentId
    }
}
