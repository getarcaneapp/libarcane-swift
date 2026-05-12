import Foundation

nonisolated public struct ContainerInfo: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let image: String
    public let state: String
    public let status: String
    public let names: [String]?
    public let labels: [String: String]?
    public let imageId: String?
    public let command: String?
    public let created: Int64?

    public var displayName: String {
        let first = names?.first?.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? ""
        return first.isEmpty ? String(id.prefix(12)) : first
    }

    public var isRunning: Bool { state.lowercased() == "running" }
    public var iconUrl: String? { labels?["com.getarcaneapp.arcane.icon"] }

    public enum CodingKeys: String, CodingKey {
        case id, image, state, status, names, labels, imageId, command, created
    }

    nonisolated public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.image = (try? container.decodeIfPresent(String.self, forKey: .image)) ?? ""
        self.state = (try? container.decodeIfPresent(String.self, forKey: .state)) ?? ""
        self.status = (try? container.decodeIfPresent(String.self, forKey: .status)) ?? ""
        self.names = try? container.decodeIfPresent([String].self, forKey: .names)
        self.labels = try? container.decodeIfPresent([String: String].self, forKey: .labels)
        self.imageId = try? container.decodeIfPresent(String.self, forKey: .imageId)
        self.command = try? container.decodeIfPresent(String.self, forKey: .command)
        self.created = try? container.decodeIfPresent(Int64.self, forKey: .created)
    }
}
