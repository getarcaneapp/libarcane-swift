import Foundation

/// Schema-tolerant `JobStatus`. Replaces the OpenAPI-generated strict type so a
/// missing optional field on an older Arcane backend (or an unexpected extra
/// field on a newer one) can't take down the jobs list.
nonisolated public struct JobStatus: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let description: String
    public let category: String
    public let schedule: String
    public let enabled: Bool
    public let canRunManually: Bool
    public let isContinuous: Bool
    public let managerOnly: Bool
    public let nextRun: Date?
    public let prerequisites: [JobPrerequisite]?
    public let settingsKey: String?

    public enum CodingKeys: String, CodingKey {
        case id, name, description, category, schedule, enabled
        case canRunManually, isContinuous, managerOnly
        case nextRun, prerequisites, settingsKey
    }

    nonisolated public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? ""
        self.description = (try? container.decodeIfPresent(String.self, forKey: .description)) ?? ""
        self.category = (try? container.decodeIfPresent(String.self, forKey: .category)) ?? ""
        self.schedule = (try? container.decodeIfPresent(String.self, forKey: .schedule)) ?? ""
        self.enabled = (try? container.decodeIfPresent(Bool.self, forKey: .enabled)) ?? true
        self.canRunManually = (try? container.decodeIfPresent(Bool.self, forKey: .canRunManually)) ?? false
        self.isContinuous = (try? container.decodeIfPresent(Bool.self, forKey: .isContinuous)) ?? false
        self.managerOnly = (try? container.decodeIfPresent(Bool.self, forKey: .managerOnly)) ?? false
        self.nextRun = try? container.decodeIfPresent(Date.self, forKey: .nextRun)
        self.prerequisites = try? container.decodeIfPresent([JobPrerequisite].self, forKey: .prerequisites)
        self.settingsKey = try? container.decodeIfPresent(String.self, forKey: .settingsKey)
    }
}

nonisolated public struct JobPrerequisite: Codable, Hashable, Sendable {
    public let isMet: Bool
    public let label: String
    public let settingKey: String
    public let settingsUrl: String?

    public enum CodingKeys: String, CodingKey {
        case isMet, label, settingKey, settingsUrl
    }

    nonisolated public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isMet = (try? container.decodeIfPresent(Bool.self, forKey: .isMet)) ?? false
        self.label = (try? container.decodeIfPresent(String.self, forKey: .label)) ?? ""
        self.settingKey = (try? container.decodeIfPresent(String.self, forKey: .settingKey)) ?? ""
        self.settingsUrl = try? container.decodeIfPresent(String.self, forKey: .settingsUrl)
    }
}

nonisolated public struct JobListResponse: Codable, Hashable, Sendable {
    public let isAgent: Bool
    public let jobs: [JobStatus]

    public enum CodingKeys: String, CodingKey {
        case isAgent, jobs
    }

    nonisolated public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isAgent = (try? container.decodeIfPresent(Bool.self, forKey: .isAgent)) ?? false
        self.jobs = (try? container.decodeIfPresent([JobStatus].self, forKey: .jobs)) ?? []
    }
}

nonisolated public struct JobRunResponse: Codable, Hashable, Sendable {
    public let message: String
    public let success: Bool

    public enum CodingKeys: String, CodingKey {
        case message, success
    }

    nonisolated public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.message = (try? container.decodeIfPresent(String.self, forKey: .message)) ?? ""
        self.success = (try? container.decodeIfPresent(Bool.self, forKey: .success)) ?? false
    }
}
