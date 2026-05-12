import Foundation

nonisolated public struct ImageInfo: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let repo: String
    public let tag: String
    public let inUse: Bool
    public let size: Int64
    public let virtualSize: Int64
    public let created: Int64
    public let repoTags: [String]?
    public let repoDigests: [String]?

    public var displayName: String {
        if let tag = repoTags?.first(where: { $0 != "<none>:<none>" }) { return tag }
        if !repo.isEmpty { return tag.isEmpty ? repo : "\(repo):\(tag)" }
        return String(id.prefix(12))
    }

    public enum CodingKeys: String, CodingKey {
        case id, repo, tag, inUse, size, virtualSize, created, repoTags, repoDigests
    }

    nonisolated public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.repo = (try? container.decodeIfPresent(String.self, forKey: .repo)) ?? ""
        self.tag = (try? container.decodeIfPresent(String.self, forKey: .tag)) ?? ""
        self.inUse = (try? container.decodeIfPresent(Bool.self, forKey: .inUse)) ?? false
        self.size = (try? container.decodeIfPresent(Int64.self, forKey: .size)) ?? 0
        self.virtualSize = (try? container.decodeIfPresent(Int64.self, forKey: .virtualSize)) ?? 0
        self.created = (try? container.decodeIfPresent(Int64.self, forKey: .created)) ?? 0
        self.repoTags = try? container.decodeIfPresent([String].self, forKey: .repoTags)
        self.repoDigests = try? container.decodeIfPresent([String].self, forKey: .repoDigests)
    }
}
