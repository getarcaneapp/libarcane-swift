import Foundation

nonisolated public struct WebhookSummary: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let enabled: Bool
    public let actionType: String
    public let targetType: String
    public let targetId: String
    public let targetName: String?
    public let tokenPrefix: String
    public let environmentId: String
    public let createdAt: Date?
    public let lastTriggeredAt: Date?

    public enum CodingKeys: String, CodingKey {
        case id, name, enabled, actionType, targetType, targetId
        case targetName, tokenPrefix, environmentId, createdAt, lastTriggeredAt
    }

    nonisolated public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? ""
        self.enabled = (try? container.decodeIfPresent(Bool.self, forKey: .enabled)) ?? false
        self.actionType = (try? container.decodeIfPresent(String.self, forKey: .actionType)) ?? ""
        self.targetType = (try? container.decodeIfPresent(String.self, forKey: .targetType)) ?? ""
        self.targetId = (try? container.decodeIfPresent(String.self, forKey: .targetId)) ?? ""
        self.targetName = try? container.decodeIfPresent(String.self, forKey: .targetName)
        self.tokenPrefix = (try? container.decodeIfPresent(String.self, forKey: .tokenPrefix)) ?? ""
        self.environmentId = (try? container.decodeIfPresent(String.self, forKey: .environmentId)) ?? ""
        self.createdAt = try? container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.lastTriggeredAt = try? container.decodeIfPresent(Date.self, forKey: .lastTriggeredAt)
    }
}
