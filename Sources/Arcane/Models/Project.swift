import Foundation

/// Schema-tolerant `Project` model. Every field decodes with `decodeIfPresent`
/// (or `try?`) and falls back to a sensible default when the backend omits it,
/// so a single missing field on an older Arcane backend can't take down a screen.
/// Only `id` throws on absence — consumers should drop unidentifiable items
/// rather than propagate duplicate-id errors.
nonisolated public struct Project: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let status: String
    public let path: String
    public let createdAt: String
    public let updatedAt: String
    public let isArchived: Bool
    public let runningCount: Int64
    public let serviceCount: Int64
    public let archivedAt: Date?
    public let composeContent: String?
    public let composeFileName: String?
    public let dirName: String?
    public let envContent: String?
    public let gitOpsManagedBy: String?
    public let gitRepositoryURL: String?
    public let hasBuildDirective: Bool?
    public let iconUrl: String?
    public let lastSyncCommit: String?
    public let redeployDisabled: Bool?
    public let relativePath: String?
    public let statusReason: String?
    public let urls: [String]?

    public var displayName: String { name }
    public var composeVersion: String? { nil }

    public var statusColor: String {
        switch status.lowercased() {
        case "running": return "green"
        case "stopped", "exited": return "red"
        case "partial", "partially running": return "orange"
        default: return "gray"
        }
    }

    public enum CodingKeys: String, CodingKey {
        case id, name, status, path, createdAt, updatedAt, isArchived
        case runningCount, serviceCount, archivedAt, composeContent
        case composeFileName, dirName, envContent, gitOpsManagedBy
        case gitRepositoryURL, hasBuildDirective, iconUrl, lastSyncCommit
        case redeployDisabled, relativePath, statusReason, urls
    }

    nonisolated public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? ""
        self.status = (try? container.decodeIfPresent(String.self, forKey: .status)) ?? ""
        self.path = (try? container.decodeIfPresent(String.self, forKey: .path)) ?? ""
        self.createdAt = (try? container.decodeIfPresent(String.self, forKey: .createdAt)) ?? ""
        self.updatedAt = (try? container.decodeIfPresent(String.self, forKey: .updatedAt)) ?? ""
        self.isArchived = (try? container.decodeIfPresent(Bool.self, forKey: .isArchived)) ?? false
        self.runningCount = (try? container.decodeIfPresent(Int64.self, forKey: .runningCount)) ?? 0
        self.serviceCount = (try? container.decodeIfPresent(Int64.self, forKey: .serviceCount)) ?? 0
        self.archivedAt = try? container.decodeIfPresent(Date.self, forKey: .archivedAt)
        self.composeContent = try? container.decodeIfPresent(String.self, forKey: .composeContent)
        self.composeFileName = try? container.decodeIfPresent(String.self, forKey: .composeFileName)
        self.dirName = try? container.decodeIfPresent(String.self, forKey: .dirName)
        self.envContent = try? container.decodeIfPresent(String.self, forKey: .envContent)
        self.gitOpsManagedBy = try? container.decodeIfPresent(String.self, forKey: .gitOpsManagedBy)
        self.gitRepositoryURL = try? container.decodeIfPresent(String.self, forKey: .gitRepositoryURL)
        self.hasBuildDirective = try? container.decodeIfPresent(Bool.self, forKey: .hasBuildDirective)
        self.iconUrl = try? container.decodeIfPresent(String.self, forKey: .iconUrl)
        self.lastSyncCommit = try? container.decodeIfPresent(String.self, forKey: .lastSyncCommit)
        self.redeployDisabled = try? container.decodeIfPresent(Bool.self, forKey: .redeployDisabled)
        self.relativePath = try? container.decodeIfPresent(String.self, forKey: .relativePath)
        self.statusReason = try? container.decodeIfPresent(String.self, forKey: .statusReason)
        self.urls = try? container.decodeIfPresent([String].self, forKey: .urls)
    }
}
