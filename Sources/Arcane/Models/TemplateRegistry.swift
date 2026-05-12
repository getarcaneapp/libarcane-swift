import Foundation

nonisolated public struct TemplateRegistry: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let url: String
    public let description: String
    public let enabled: Bool
    public let lastFetchError: String?

    public enum CodingKeys: String, CodingKey {
        case id, name, url, description, enabled, lastFetchError
    }

    nonisolated public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? ""
        self.url = (try? container.decodeIfPresent(String.self, forKey: .url)) ?? ""
        self.description = (try? container.decodeIfPresent(String.self, forKey: .description)) ?? ""
        self.enabled = (try? container.decodeIfPresent(Bool.self, forKey: .enabled)) ?? false
        self.lastFetchError = try? container.decodeIfPresent(String.self, forKey: .lastFetchError)
    }
}
