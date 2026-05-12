import Foundation

nonisolated public struct ContainerRegistry: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let url: String
    public let username: String
    public let description: String?
    public let enabled: Bool
    public let insecure: Bool
    public let registryType: String
    public let awsAccessKeyId: String?
    public let awsRegion: String?
    public let createdAt: Date?
    public let updatedAt: Date?

    public var name: String? { url }

    public enum CodingKeys: String, CodingKey {
        case id, url, username, description, enabled, insecure, registryType
        case awsAccessKeyId, awsRegion, createdAt, updatedAt
    }

    nonisolated public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.url = (try? container.decodeIfPresent(String.self, forKey: .url)) ?? ""
        self.username = (try? container.decodeIfPresent(String.self, forKey: .username)) ?? ""
        self.description = try? container.decodeIfPresent(String.self, forKey: .description)
        self.enabled = (try? container.decodeIfPresent(Bool.self, forKey: .enabled)) ?? false
        self.insecure = (try? container.decodeIfPresent(Bool.self, forKey: .insecure)) ?? false
        self.registryType = (try? container.decodeIfPresent(String.self, forKey: .registryType)) ?? "generic"
        self.awsAccessKeyId = try? container.decodeIfPresent(String.self, forKey: .awsAccessKeyId)
        self.awsRegion = try? container.decodeIfPresent(String.self, forKey: .awsRegion)
        self.createdAt = try? container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.updatedAt = try? container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}
