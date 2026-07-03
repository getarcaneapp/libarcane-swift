import Foundation

public struct Role: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var description: String?
    public var permissions: [String]
    public var builtIn: Bool
    public var assignedUserCount: Int
    public var createdAt: Date
    public var updatedAt: Date?

    public init(
        id: String,
        name: String,
        description: String? = nil,
        permissions: [String] = [],
        builtIn: Bool = false,
        assignedUserCount: Int = 0,
        createdAt: Date,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.permissions = permissions
        self.builtIn = builtIn
        self.assignedUserCount = assignedUserCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, description, permissions, builtIn, assignedUserCount, createdAt, updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        permissions = try container.decodeIfPresent([String].self, forKey: .permissions) ?? []
        builtIn = try container.decodeIfPresent(Bool.self, forKey: .builtIn) ?? false
        assignedUserCount = try container.decodeIfPresent(Int.self, forKey: .assignedUserCount) ?? 0
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }

    /// Stable built-in role IDs seeded by the v2 backend migration. Custom
    /// roles will have any other ID and are user-defined.
    public enum BuiltIn {
        public static let admin = "role_admin"
        public static let editor = "role_editor"
        public static let noShellEditor = "role_no_shell_editor"
        public static let deployer = "role_deployer"
        public static let monitor = "role_monitor"
        public static let viewer = "role_viewer"
    }
}

public struct CreateRole: Codable, Hashable, Sendable {
    public var name: String
    public var description: String?
    public var permissions: [String]

    public init(name: String, description: String? = nil, permissions: [String]) {
        self.name = name
        self.description = description
        self.permissions = permissions
    }
}

public struct UpdateRole: Codable, Hashable, Sendable {
    public var name: String
    public var description: String?
    public var permissions: [String]

    public init(name: String, description: String? = nil, permissions: [String]) {
        self.name = name
        self.description = description
        self.permissions = permissions
    }
}
