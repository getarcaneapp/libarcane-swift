import Foundation

/// Kinds of dashboard action items. Unknown kinds from newer servers decode
/// to `.unknown` instead of failing the whole snapshot — the dashboard stream
/// dies wholesale on any undecodable line, so action items must never poison it.
public enum ActionItemKind: Hashable, Sendable, Codable {
    case stoppedContainers
    case imageUpdates
    case actionableVulnerabilities
    case expiringKeys
    case unknown(String)

    public var rawValue: String {
        switch self {
        case .stoppedContainers: return "stopped_containers"
        case .imageUpdates: return "image_updates"
        case .actionableVulnerabilities: return "actionable_vulnerabilities"
        case .expiringKeys: return "expiring_keys"
        case let .unknown(value): return value
        }
    }

    public init(rawValue: String) {
        switch rawValue {
        case "stopped_containers": self = .stoppedContainers
        case "image_updates": self = .imageUpdates
        case "actionable_vulnerabilities": self = .actionableVulnerabilities
        case "expiring_keys": self = .expiringKeys
        default: self = .unknown(rawValue)
        }
    }

    public init(from decoder: Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// Severity of a dashboard action item; unknown severities decode to `.unknown`.
public enum ActionItemSeverity: Hashable, Sendable, Codable {
    case warning
    case critical
    case unknown(String)

    public var rawValue: String {
        switch self {
        case .warning: return "warning"
        case .critical: return "critical"
        case let .unknown(value): return value
        }
    }

    public init(rawValue: String) {
        switch rawValue {
        case "warning": self = .warning
        case "critical": self = .critical
        default: self = .unknown(rawValue)
        }
    }

    public init(from decoder: Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// A single attention item rendered on the dashboard.
public struct ActionItem: Codable, Hashable, Sendable {
    public var kind: ActionItemKind
    public var count: Int
    public var severity: ActionItemSeverity

    public init(kind: ActionItemKind, count: Int, severity: ActionItemSeverity) {
        self.kind = kind
        self.count = count
        self.severity = severity
    }
}

/// Collection of dashboard action items.
public struct ActionItems: Codable, Hashable, Sendable {
    public var items: [ActionItem]

    public init(items: [ActionItem] = []) {
        self.items = items
    }
}

/// Settings payload carried in dashboard snapshots. Currently empty server-side
/// — modeled as an opaque dictionary so future fields land transparently.
public struct DashboardSnapshotSettings: Codable, Hashable, Sendable {
    public init() {}
}

/// Dashboard environment-overview row, one per visible environment.
///
/// The full `environment` blob is preserved as JSON until the environments
/// domain is ported alongside this code.
public struct DashboardEnvironmentOverview: Codable, Hashable, Sendable {
    public var environment: JSONValue
    public var containers: ContainerStatusCounts
    public var imageUsageCounts: ImageUsageCounts
    public var actionItems: ActionItems
    public var settings: DashboardSnapshotSettings
    public var versionInfo: VersionInfo?
    public var snapshotState: EnvironmentSnapshotState
    public var snapshotError: String?

    public init(
        environment: JSONValue,
        containers: ContainerStatusCounts,
        imageUsageCounts: ImageUsageCounts,
        actionItems: ActionItems,
        settings: DashboardSnapshotSettings,
        versionInfo: VersionInfo? = nil,
        snapshotState: EnvironmentSnapshotState,
        snapshotError: String? = nil
    ) {
        self.environment = environment
        self.containers = containers
        self.imageUsageCounts = imageUsageCounts
        self.actionItems = actionItems
        self.settings = settings
        self.versionInfo = versionInfo
        self.snapshotState = snapshotState
        self.snapshotError = snapshotError
    }
}

public enum EnvironmentSnapshotState: String, Codable, Hashable, Sendable {
    case ready
    case skipped
    case error
}

public struct DashboardEnvironmentsSummary: Codable, Hashable, Sendable {
    public var totalEnvironments: Int
    public var onlineEnvironments: Int
    public var standbyEnvironments: Int
    public var offlineEnvironments: Int
    public var pendingEnvironments: Int
    public var errorEnvironments: Int
    public var disabledEnvironments: Int
    public var containers: ContainerStatusCounts
    public var imageUsageCounts: ImageUsageCounts
    public var environmentsWithActionItems: Int

    public init(
        totalEnvironments: Int = 0,
        onlineEnvironments: Int = 0,
        standbyEnvironments: Int = 0,
        offlineEnvironments: Int = 0,
        pendingEnvironments: Int = 0,
        errorEnvironments: Int = 0,
        disabledEnvironments: Int = 0,
        containers: ContainerStatusCounts = .init(),
        imageUsageCounts: ImageUsageCounts = .init(),
        environmentsWithActionItems: Int = 0
    ) {
        self.totalEnvironments = totalEnvironments
        self.onlineEnvironments = onlineEnvironments
        self.standbyEnvironments = standbyEnvironments
        self.offlineEnvironments = offlineEnvironments
        self.pendingEnvironments = pendingEnvironments
        self.errorEnvironments = errorEnvironments
        self.disabledEnvironments = disabledEnvironments
        self.containers = containers
        self.imageUsageCounts = imageUsageCounts
        self.environmentsWithActionItems = environmentsWithActionItems
    }
}

public struct DashboardEnvironmentsOverview: Codable, Hashable, Sendable {
    public var summary: DashboardEnvironmentsSummary
    public var environments: [DashboardEnvironmentOverview]

    public init(
        summary: DashboardEnvironmentsSummary,
        environments: [DashboardEnvironmentOverview] = []
    ) {
        self.summary = summary
        self.environments = environments
    }
}

/// Container table payload on the dashboard.
public struct DashboardSnapshotContainers: Codable, Hashable, Sendable {
    public var data: [ContainerSummary]
    public var counts: ContainerStatusCounts
    public var pagination: PaginationResponse

    public init(
        data: [ContainerSummary] = [],
        counts: ContainerStatusCounts = .init(),
        pagination: PaginationResponse
    ) {
        self.data = data
        self.counts = counts
        self.pagination = pagination
    }

    enum CodingKeys: String, CodingKey {
        case data, counts, pagination
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Stream events trim the table rows to JSON null ("data": null) — only
        // the aggregate counts are meaningful there.
        data = try container.decodeIfPresent([ContainerSummary].self, forKey: .data) ?? []
        counts = try container.decode(ContainerStatusCounts.self, forKey: .counts)
        pagination = try container.decode(PaginationResponse.self, forKey: .pagination)
    }
}

/// Image table payload on the dashboard. Images are kept as opaque JSON until
/// the image-summary type is fully ported.
public struct DashboardSnapshotImages: Codable, Hashable, Sendable {
    public var data: [JSONValue]
    public var pagination: PaginationResponse

    public init(data: [JSONValue] = [], pagination: PaginationResponse) {
        self.data = data
        self.pagination = pagination
    }

    enum CodingKeys: String, CodingKey {
        case data, pagination
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Stream events trim the table rows to JSON null ("data": null).
        data = try container.decodeIfPresent([JSONValue].self, forKey: .data) ?? []
        pagination = try container.decode(PaginationResponse.self, forKey: .pagination)
    }
}

/// Top-level dashboard first-paint snapshot.
public struct DashboardSnapshot: Codable, Hashable, Sendable {
    public var containers: DashboardSnapshotContainers
    public var images: DashboardSnapshotImages
    public var imageUsageCounts: ImageUsageCounts
    public var actionItems: ActionItems
    public var settings: DashboardSnapshotSettings
    /// Application version metadata for the environment, when available.
    public var versionInfo: VersionInfo?

    public init(
        containers: DashboardSnapshotContainers,
        images: DashboardSnapshotImages,
        imageUsageCounts: ImageUsageCounts,
        actionItems: ActionItems,
        settings: DashboardSnapshotSettings,
        versionInfo: VersionInfo? = nil
    ) {
        self.containers = containers
        self.images = images
        self.imageUsageCounts = imageUsageCounts
        self.actionItems = actionItems
        self.settings = settings
        self.versionInfo = versionInfo
    }
}
