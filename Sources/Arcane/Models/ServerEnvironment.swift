import Foundation

nonisolated public struct ServerEnvironment: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let name: String?
    public let apiUrl: String
    public let status: String
    public let enabled: Bool
    public let isEdge: Bool
    public let connected: Bool?
    public let lastSeen: Date?
    public let lastHeartbeat: Date?
    public let lastPollAt: Date?
    public let connectedAt: Date?

    public var url: String? { apiUrl.isEmpty ? nil : apiUrl }
    public var agentVersion: String? { nil }
    public var isOnline: Bool? {
        let lower = status.lowercased()
        return lower == "online" || lower == "up" || connected == true
    }

    public enum CodingKeys: String, CodingKey {
        case id, name, apiUrl, status, enabled, isEdge, connected
        case lastSeen, lastHeartbeat, lastPollAt, connectedAt
    }

    nonisolated public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try? container.decodeIfPresent(String.self, forKey: .name)
        self.apiUrl = (try? container.decodeIfPresent(String.self, forKey: .apiUrl)) ?? ""
        self.status = (try? container.decodeIfPresent(String.self, forKey: .status)) ?? ""
        self.enabled = (try? container.decodeIfPresent(Bool.self, forKey: .enabled)) ?? true
        self.isEdge = (try? container.decodeIfPresent(Bool.self, forKey: .isEdge)) ?? false
        self.connected = try? container.decodeIfPresent(Bool.self, forKey: .connected)
        self.lastSeen = try? container.decodeIfPresent(Date.self, forKey: .lastSeen)
        self.lastHeartbeat = try? container.decodeIfPresent(Date.self, forKey: .lastHeartbeat)
        self.lastPollAt = try? container.decodeIfPresent(Date.self, forKey: .lastPollAt)
        self.connectedAt = try? container.decodeIfPresent(Date.self, forKey: .connectedAt)
    }
}
