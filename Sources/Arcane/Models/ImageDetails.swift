import Foundation

nonisolated public struct ImageDetails: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let created: String
    public let architecture: String
    public let os: String
    public let size: Int64
    public let author: String
    public let comment: String
    public let repoTags: [String]?
    public let repoDigests: [String]?
    public let config: ImageConfig?

    public enum CodingKeys: String, CodingKey {
        case id, created, architecture, os, size, author, comment
        case repoTags, repoDigests, config
    }

    nonisolated public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.created = (try? container.decodeIfPresent(String.self, forKey: .created)) ?? ""
        self.architecture = (try? container.decodeIfPresent(String.self, forKey: .architecture)) ?? ""
        self.os = (try? container.decodeIfPresent(String.self, forKey: .os)) ?? ""
        self.size = (try? container.decodeIfPresent(Int64.self, forKey: .size)) ?? 0
        self.author = (try? container.decodeIfPresent(String.self, forKey: .author)) ?? ""
        self.comment = (try? container.decodeIfPresent(String.self, forKey: .comment)) ?? ""
        self.repoTags = try? container.decodeIfPresent([String].self, forKey: .repoTags)
        self.repoDigests = try? container.decodeIfPresent([String].self, forKey: .repoDigests)
        self.config = try? container.decodeIfPresent(ImageConfig.self, forKey: .config)
    }
}

nonisolated public struct ImageConfig: Codable, Hashable, Sendable {
    public let cmd: [String]?
    public let env: [String]?
    public let workingDir: String?
    public let exposedPorts: [String: JSONValue]?
    public let volumes: [String: JSONValue]?

    public var entrypoint: [String]? { nil }
    public var user: String? { nil }
    public var labels: [String: String]? { nil }

    public enum CodingKeys: String, CodingKey {
        case cmd, env, workingDir, exposedPorts, volumes
    }

    nonisolated public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cmd = try? container.decodeIfPresent([String].self, forKey: .cmd)
        self.env = try? container.decodeIfPresent([String].self, forKey: .env)
        self.workingDir = try? container.decodeIfPresent(String.self, forKey: .workingDir)
        self.exposedPorts = try? container.decodeIfPresent([String: JSONValue].self, forKey: .exposedPorts)
        self.volumes = try? container.decodeIfPresent([String: JSONValue].self, forKey: .volumes)
    }
}
