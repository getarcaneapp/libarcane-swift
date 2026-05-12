import Foundation

nonisolated public struct APIKey: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let keyPrefix: String
    public let isStatic: Bool
    public let description: String?
    public let userId: String?
    public let createdAt: Date?
    public let updatedAt: Date?
    public let expiresAt: Date?
    public let lastUsedAt: Date?

    public var isProtected: Bool? { isStatic }
    public var permissions: [String]? { nil }

    public enum CodingKeys: String, CodingKey {
        case id, name, keyPrefix, isStatic, description, userId
        case createdAt, updatedAt, expiresAt, lastUsedAt
    }

    nonisolated public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? ""
        self.keyPrefix = (try? container.decodeIfPresent(String.self, forKey: .keyPrefix)) ?? ""
        self.isStatic = (try? container.decodeIfPresent(Bool.self, forKey: .isStatic)) ?? false
        self.description = try? container.decodeIfPresent(String.self, forKey: .description)
        self.userId = try? container.decodeIfPresent(String.self, forKey: .userId)
        self.createdAt = try? container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.updatedAt = try? container.decodeIfPresent(Date.self, forKey: .updatedAt)
        self.expiresAt = try? container.decodeIfPresent(Date.self, forKey: .expiresAt)
        self.lastUsedAt = try? container.decodeIfPresent(Date.self, forKey: .lastUsedAt)
    }
}
