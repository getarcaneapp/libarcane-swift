import Foundation

/// A single probe result from the healthcheck log.
public struct ContainerHealthLogEntry: Codable, Hashable, Sendable {
    public var start: String?
    public var end: String?
    public var exitCode: Int
    public var output: String?

    public init(
        start: String? = nil,
        end: String? = nil,
        exitCode: Int = 0,
        output: String? = nil
    ) {
        self.start = start
        self.end = end
        self.exitCode = exitCode
        self.output = output
    }
}

/// Current healthcheck state of a container.
public struct ContainerHealth: Codable, Hashable, Sendable {
    public var status: String
    public var failingStreak: Int
    public var log: [ContainerHealthLogEntry]?

    public init(
        status: String,
        failingStreak: Int = 0,
        log: [ContainerHealthLogEntry]? = nil
    ) {
        self.status = status
        self.failingStreak = failingStreak
        self.log = log
    }
}

/// Container healthcheck configuration. Duration values are expressed in nanoseconds.
public struct ContainerHealthcheck: Codable, Hashable, Sendable {
    public var test: [String]?
    public var interval: Int64?
    public var timeout: Int64?
    public var startPeriod: Int64?
    public var startInterval: Int64?
    public var retries: Int?

    public init(
        test: [String]? = nil,
        interval: Int64? = nil,
        timeout: Int64? = nil,
        startPeriod: Int64? = nil,
        startInterval: Int64? = nil,
        retries: Int? = nil
    ) {
        self.test = test
        self.interval = interval
        self.timeout = timeout
        self.startPeriod = startPeriod
        self.startInterval = startInterval
        self.retries = retries
    }
}

/// State of a container.
public struct ContainerState: Codable, Hashable, Sendable {
    public var status: String
    public var running: Bool
    public var exitCode: Int?
    public var startedAt: String?
    public var finishedAt: String?
    public var health: ContainerHealth?

    public init(
        status: String,
        running: Bool,
        exitCode: Int? = nil,
        startedAt: String? = nil,
        finishedAt: String? = nil,
        health: ContainerHealth? = nil
    ) {
        self.status = status
        self.running = running
        self.exitCode = exitCode
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.health = health
    }
}

/// Configuration details for a container.
public struct ContainerConfig: Codable, Hashable, Sendable {
    public var env: [String]?
    public var cmd: [String]?
    public var entrypoint: [String]?
    public var workingDir: String?
    public var user: String?
    public var healthcheck: ContainerHealthcheck?

    public init(
        env: [String]? = nil,
        cmd: [String]? = nil,
        entrypoint: [String]? = nil,
        workingDir: String? = nil,
        user: String? = nil,
        healthcheck: ContainerHealthcheck? = nil
    ) {
        self.env = env
        self.cmd = cmd
        self.entrypoint = entrypoint
        self.workingDir = workingDir
        self.user = user
        self.healthcheck = healthcheck
    }
}

/// Docker Compose project information extracted from container labels.
public struct ContainerComposeInfo: Codable, Hashable, Sendable {
    public var projectName: String
    public var serviceName: String
    public var workingDir: String?
    public var configFiles: String?

    public init(
        projectName: String,
        serviceName: String,
        workingDir: String? = nil,
        configFiles: String? = nil
    ) {
        self.projectName = projectName
        self.serviceName = serviceName
        self.workingDir = workingDir
        self.configFiles = configFiles
    }
}
