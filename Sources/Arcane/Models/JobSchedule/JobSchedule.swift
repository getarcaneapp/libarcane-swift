import Foundation

/// JobScheduleConfig represents the configured intervals (in minutes) for background jobs.
public struct JobScheduleConfig: Codable, Hashable, Sendable {
    public var environmentHealthInterval: String
    public var eventCleanupInterval: String
    public var expiredSessionsCleanupInterval: String
    public var autoUpdateInterval: String
    public var dockerClientRefreshInterval: String
    public var pollingInterval: String
    public var scheduledPruneInterval: String
    public var gitopsSyncInterval: String
    public var vulnerabilityScanInterval: String
    public var autoHealInterval: String

    public init(
        environmentHealthInterval: String,
        eventCleanupInterval: String,
        expiredSessionsCleanupInterval: String,
        autoUpdateInterval: String,
        dockerClientRefreshInterval: String,
        pollingInterval: String,
        scheduledPruneInterval: String,
        gitopsSyncInterval: String,
        vulnerabilityScanInterval: String,
        autoHealInterval: String
    ) {
        self.environmentHealthInterval = environmentHealthInterval
        self.eventCleanupInterval = eventCleanupInterval
        self.expiredSessionsCleanupInterval = expiredSessionsCleanupInterval
        self.autoUpdateInterval = autoUpdateInterval
        self.dockerClientRefreshInterval = dockerClientRefreshInterval
        self.pollingInterval = pollingInterval
        self.scheduledPruneInterval = scheduledPruneInterval
        self.gitopsSyncInterval = gitopsSyncInterval
        self.vulnerabilityScanInterval = vulnerabilityScanInterval
        self.autoHealInterval = autoHealInterval
    }
}

/// UpdateJobScheduleConfig updates job schedule intervals (in minutes). Nil fields are ignored.
public struct UpdateJobScheduleConfig: Codable, Hashable, Sendable {
    public var environmentHealthInterval: String?
    public var eventCleanupInterval: String?
    public var expiredSessionsCleanupInterval: String?
    public var autoUpdateInterval: String?
    public var dockerClientRefreshInterval: String?
    public var pollingInterval: String?
    public var scheduledPruneInterval: String?
    public var gitopsSyncInterval: String?
    public var vulnerabilityScanInterval: String?
    public var autoHealInterval: String?

    public init(
        environmentHealthInterval: String? = nil,
        eventCleanupInterval: String? = nil,
        expiredSessionsCleanupInterval: String? = nil,
        autoUpdateInterval: String? = nil,
        dockerClientRefreshInterval: String? = nil,
        pollingInterval: String? = nil,
        scheduledPruneInterval: String? = nil,
        gitopsSyncInterval: String? = nil,
        vulnerabilityScanInterval: String? = nil,
        autoHealInterval: String? = nil
    ) {
        self.environmentHealthInterval = environmentHealthInterval
        self.eventCleanupInterval = eventCleanupInterval
        self.expiredSessionsCleanupInterval = expiredSessionsCleanupInterval
        self.autoUpdateInterval = autoUpdateInterval
        self.dockerClientRefreshInterval = dockerClientRefreshInterval
        self.pollingInterval = pollingInterval
        self.scheduledPruneInterval = scheduledPruneInterval
        self.gitopsSyncInterval = gitopsSyncInterval
        self.vulnerabilityScanInterval = vulnerabilityScanInterval
        self.autoHealInterval = autoHealInterval
    }
}

/// Status and metadata for a background job.
public struct JobStatus: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var description: String
    public var category: String
    public var schedule: String
    public var nextRun: Date?
    public var enabled: Bool
    public var managerOnly: Bool
    public var isContinuous: Bool
    public var canRunManually: Bool
    public var prerequisites: [JobPrerequisite]
    public var settingsKey: String?

    public init(
        id: String,
        name: String,
        description: String,
        category: String,
        schedule: String,
        nextRun: Date? = nil,
        enabled: Bool,
        managerOnly: Bool,
        isContinuous: Bool,
        canRunManually: Bool,
        prerequisites: [JobPrerequisite] = [],
        settingsKey: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.schedule = schedule
        self.nextRun = nextRun
        self.enabled = enabled
        self.managerOnly = managerOnly
        self.isContinuous = isContinuous
        self.canRunManually = canRunManually
        self.prerequisites = prerequisites
        self.settingsKey = settingsKey
    }
}

public struct JobPrerequisite: Codable, Hashable, Sendable {
    public var settingKey: String
    public var label: String
    public var isMet: Bool
    public var settingsUrl: String?

    public init(settingKey: String, label: String, isMet: Bool, settingsUrl: String? = nil) {
        self.settingKey = settingKey
        self.label = label
        self.isMet = isMet
        self.settingsUrl = settingsUrl
    }
}

public struct JobListResponse: Codable, Hashable, Sendable {
    public var jobs: [JobStatus]
    public var isAgent: Bool

    public init(jobs: [JobStatus], isAgent: Bool) {
        self.jobs = jobs
        self.isAgent = isAgent
    }
}

public struct JobRunResponse: Codable, Hashable, Sendable {
    public var success: Bool
    public var message: String

    public init(success: Bool, message: String) {
        self.success = success
        self.message = message
    }
}
