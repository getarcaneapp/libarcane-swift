import Foundation

/// A container summary as returned by the list endpoint.
public struct ContainerSummary: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var names: [String]
    public var image: String
    public var imageId: String
    public var command: String
    public var created: Int64
    public var ports: [ContainerPort]
    public var labels: [String: String]
    public var state: String
    public var status: String
    public var hostConfig: ContainerHostConfig
    public var networkSettings: ContainerNetworkSettings
    public var mounts: [ContainerMount]
    public var updateInfo: ImageUpdateInfo?
    public var redeployDisabled: Bool?

    public init(
        id: String,
        names: [String] = [],
        image: String,
        imageId: String,
        command: String = "",
        created: Int64 = 0,
        ports: [ContainerPort] = [],
        labels: [String: String] = [:],
        state: String,
        status: String,
        hostConfig: ContainerHostConfig = .init(),
        networkSettings: ContainerNetworkSettings = .init(),
        mounts: [ContainerMount] = [],
        updateInfo: ImageUpdateInfo? = nil,
        redeployDisabled: Bool? = nil
    ) {
        self.id = id
        self.names = names
        self.image = image
        self.imageId = imageId
        self.command = command
        self.created = created
        self.ports = ports
        self.labels = labels
        self.state = state
        self.status = status
        self.hostConfig = hostConfig
        self.networkSettings = networkSettings
        self.mounts = mounts
        self.updateInfo = updateInfo
        self.redeployDisabled = redeployDisabled
    }
}

/// A group of container summaries, e.g. by Compose project.
public struct ContainerSummaryGroup: Codable, Hashable, Sendable {
    public var groupName: String
    public var items: [ContainerSummary]

    public init(groupName: String, items: [ContainerSummary] = []) {
        self.groupName = groupName
        self.items = items
    }
}

/// Counts of containers by status.
public struct ContainerStatusCounts: Codable, Hashable, Sendable {
    public var runningContainers: Int
    public var stoppedContainers: Int
    public var totalContainers: Int

    public init(runningContainers: Int = 0, stoppedContainers: Int = 0, totalContainers: Int = 0) {
        self.runningContainers = runningContainers
        self.stoppedContainers = stoppedContainers
        self.totalContainers = totalContainers
    }
}

/// Result of a container batch action (start/stop/etc).
public struct ContainerActionResult: Codable, Hashable, Sendable {
    public var started: [String]?
    public var stopped: [String]?
    public var failed: [String]?
    public var success: Bool
    public var errors: [String]?

    public init(
        started: [String]? = nil,
        stopped: [String]? = nil,
        failed: [String]? = nil,
        success: Bool = false,
        errors: [String]? = nil
    ) {
        self.started = started
        self.stopped = stopped
        self.failed = failed
        self.success = success
        self.errors = errors
    }
}

/// A newly created container.
public struct ContainerCreated: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var image: String
    public var status: String
    public var created: String

    public init(id: String, name: String, image: String, status: String, created: String) {
        self.id = id
        self.name = name
        self.image = image
        self.status = status
        self.created = created
    }
}
