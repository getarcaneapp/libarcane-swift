import Foundation

public struct User: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var username: String
    public var displayName: String?
    public var email: String?
    /// Legacy string-role list. On a v1 server this is the source of truth.
    /// On a v2 server (where `roleAssignments` is populated) this is
    /// synthesized as the deduped list of role IDs from `roleAssignments`,
    /// so call sites doing `user.roles.contains(...)` keep working.
    public var roles: [String]
    public var canDelete: Bool
    public var oidcSubjectId: String?
    public var locale: String?
    public var createdAt: String?
    public var updatedAt: String?
    public var requiresPasswordChange: Bool
    /// Role assignments held by the user. `nil` on a v1 server.
    public var roleAssignments: [RoleAssignmentSummary]?
    /// Effective permissions keyed by environment ID. The reserved key
    /// `"global"` holds permissions that apply across every environment and
    /// to org-level endpoints. `nil` on a v1 server.
    public var permissionsByEnv: [String: [String]]?

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
        requiresPasswordChange: Bool = false,
        roleAssignments: [RoleAssignmentSummary]? = nil,
        permissionsByEnv: [String: [String]]? = nil
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
        self.roleAssignments = roleAssignments
        self.permissionsByEnv = permissionsByEnv
    }

    private enum CodingKeys: String, CodingKey {
        case id, username, displayName, email
        case roles
        case canDelete, oidcSubjectId, locale, createdAt, updatedAt, requiresPasswordChange
        case roleAssignments, permissionsByEnv
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        canDelete = try container.decodeIfPresent(Bool.self, forKey: .canDelete) ?? false
        oidcSubjectId = try container.decodeIfPresent(String.self, forKey: .oidcSubjectId)
        locale = try container.decodeIfPresent(String.self, forKey: .locale)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        requiresPasswordChange = try container.decodeIfPresent(Bool.self, forKey: .requiresPasswordChange) ?? false

        let decodedRoles = try container.decodeIfPresent([String].self, forKey: .roles)
        let decodedAssignments = try container.decodeIfPresent([RoleAssignmentSummary].self, forKey: .roleAssignments)
        let decodedPerms = try container.decodeIfPresent([String: [String]].self, forKey: .permissionsByEnv)

        roleAssignments = decodedAssignments
        permissionsByEnv = decodedPerms

        if let decodedRoles {
            roles = decodedRoles
        } else if let decodedAssignments {
            var seen = Set<String>()
            roles = decodedAssignments.compactMap { assignment in
                seen.insert(assignment.roleId).inserted ? assignment.roleId : nil
            }
        } else {
            roles = []
        }
    }
}

public struct CreateUser: Codable, Hashable, Sendable {
    public var username: String
    public var password: String
    public var displayName: String?
    public var email: String?
    /// Initial role assignments by name.
    ///
    /// - **v1 servers**: included on the wire and applied. Pass strings like
    ///   `["admin"]` or `["user"]`.
    /// - **v2 (RBAC) servers**: must be `nil`. The v2 server rejects a
    ///   CreateUser body containing `roles`. Call
    ///   `UsersService.setRoleAssignments(userId:assignments:)` after create
    ///   to grant assignments instead.
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
    /// Role list update.
    ///
    /// - **v1 servers**: included on the wire and applied. Pass strings like
    ///   `["admin"]` or `[]`.
    /// - **v2 (RBAC) servers**: must be `nil`. Use
    ///   `UsersService.setRoleAssignments(userId:assignments:)` instead.
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
