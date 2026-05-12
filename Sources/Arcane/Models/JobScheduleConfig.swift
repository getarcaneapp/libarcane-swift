import Foundation

/// Schema-tolerant `JobScheduleConfig`. The OpenAPI version is strict on every
/// field; this lets a missing or extra cron entry through without taking down
/// the schedules screen.
nonisolated public struct JobScheduleConfig: Codable, Hashable, Sendable {
    public let autoHealInterval: String
    public let autoUpdateInterval: String
    public let dockerClientRefreshInterval: String
    public let environmentHealthInterval: String
    public let eventCleanupInterval: String
    public let gitopsSyncInterval: String
    public let pollingInterval: String
    public let scheduledPruneInterval: String
    public let vulnerabilityScanInterval: String

    public enum CodingKeys: String, CodingKey {
        case autoHealInterval
        case autoUpdateInterval
        case dockerClientRefreshInterval
        case environmentHealthInterval
        case eventCleanupInterval
        case gitopsSyncInterval
        case pollingInterval
        case scheduledPruneInterval
        case vulnerabilityScanInterval
    }

    nonisolated public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.autoHealInterval = (try? container.decodeIfPresent(String.self, forKey: .autoHealInterval)) ?? ""
        self.autoUpdateInterval = (try? container.decodeIfPresent(String.self, forKey: .autoUpdateInterval)) ?? ""
        self.dockerClientRefreshInterval = (try? container.decodeIfPresent(String.self, forKey: .dockerClientRefreshInterval)) ?? ""
        self.environmentHealthInterval = (try? container.decodeIfPresent(String.self, forKey: .environmentHealthInterval)) ?? ""
        self.eventCleanupInterval = (try? container.decodeIfPresent(String.self, forKey: .eventCleanupInterval)) ?? ""
        self.gitopsSyncInterval = (try? container.decodeIfPresent(String.self, forKey: .gitopsSyncInterval)) ?? ""
        self.pollingInterval = (try? container.decodeIfPresent(String.self, forKey: .pollingInterval)) ?? ""
        self.scheduledPruneInterval = (try? container.decodeIfPresent(String.self, forKey: .scheduledPruneInterval)) ?? ""
        self.vulnerabilityScanInterval = (try? container.decodeIfPresent(String.self, forKey: .vulnerabilityScanInterval)) ?? ""
    }
}
