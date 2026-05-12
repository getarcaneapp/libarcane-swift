import Foundation

nonisolated public struct ArcaneUser: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let username: String
    public let email: String?
    public let displayName: String?
    public let locale: String?
    public let oidcSubjectId: String?
    public let roles: [String]?
    public let canDelete: Bool
    public let requiresPasswordChange: Bool
    public let createdAt: String?
    public let updatedAt: String?

    public var isAdmin: Bool { roles?.contains("admin") ?? false }
    public var displayUsername: String { username }
    public var lastLogin: String? { nil }

    public enum CodingKeys: String, CodingKey {
        case id, username, email, displayName, locale, oidcSubjectId
        case roles, canDelete, requiresPasswordChange, createdAt, updatedAt
    }

    nonisolated public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.username = (try? container.decodeIfPresent(String.self, forKey: .username)) ?? ""
        self.email = try? container.decodeIfPresent(String.self, forKey: .email)
        self.displayName = try? container.decodeIfPresent(String.self, forKey: .displayName)
        self.locale = try? container.decodeIfPresent(String.self, forKey: .locale)
        self.oidcSubjectId = try? container.decodeIfPresent(String.self, forKey: .oidcSubjectId)
        self.roles = try? container.decodeIfPresent([String].self, forKey: .roles)
        self.canDelete = (try? container.decodeIfPresent(Bool.self, forKey: .canDelete)) ?? true
        self.requiresPasswordChange = (try? container.decodeIfPresent(Bool.self, forKey: .requiresPasswordChange)) ?? false
        self.createdAt = try? container.decodeIfPresent(String.self, forKey: .createdAt)
        self.updatedAt = try? container.decodeIfPresent(String.self, forKey: .updatedAt)
    }

    nonisolated public init(
        id: String,
        username: String,
        email: String? = nil,
        displayName: String? = nil,
        locale: String? = nil,
        oidcSubjectId: String? = nil,
        roles: [String]? = nil,
        canDelete: Bool = true,
        requiresPasswordChange: Bool = false,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.displayName = displayName
        self.locale = locale
        self.oidcSubjectId = oidcSubjectId
        self.roles = roles
        self.canDelete = canDelete
        self.requiresPasswordChange = requiresPasswordChange
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
