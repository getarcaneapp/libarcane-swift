import Foundation

/// VolumeUsageData mirrors Docker SDK volume usage data.
public struct VolumeUsageData: Codable, Hashable, Sendable {
    public var size: Int64
    public var refCount: Int64

    public init(size: Int64 = 0, refCount: Int64 = 0) {
        self.size = size
        self.refCount = refCount
    }

    private enum CodingKeys: String, CodingKey {
        case size = "Size"
        case refCount = "RefCount"
    }
}

/// Volume represents a Docker volume.
public struct Volume: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var driver: String
    public var mountpoint: String
    public var scope: String
    public var options: [String: String]
    public var labels: [String: String]
    public var createdAt: String
    public var inUse: Bool
    public var usageData: VolumeUsageData?
    public var size: Int64
    public var containers: [String]

    public init(
        id: String,
        name: String,
        driver: String,
        mountpoint: String,
        scope: String,
        options: [String: String] = [:],
        labels: [String: String] = [:],
        createdAt: String,
        inUse: Bool = false,
        usageData: VolumeUsageData? = nil,
        size: Int64 = 0,
        containers: [String] = []
    ) {
        self.id = id
        self.name = name
        self.driver = driver
        self.mountpoint = mountpoint
        self.scope = scope
        self.options = options
        self.labels = labels
        self.createdAt = createdAt
        self.inUse = inUse
        self.usageData = usageData
        self.size = size
        self.containers = containers
    }
}

/// VolumeUsageCounts contains counts of volumes by usage status.
public struct VolumeUsageCounts: Codable, Hashable, Sendable {
    public var inuse: Int
    public var unused: Int
    public var total: Int

    public init(inuse: Int = 0, unused: Int = 0, total: Int = 0) {
        self.inuse = inuse
        self.unused = unused
        self.total = total
    }
}

/// VolumePruneReport is the result of a volume prune operation.
public struct VolumePruneReport: Codable, Hashable, Sendable {
    public var volumesDeleted: [String]
    public var spaceReclaimed: UInt64

    public init(volumesDeleted: [String] = [], spaceReclaimed: UInt64 = 0) {
        self.volumesDeleted = volumesDeleted
        self.spaceReclaimed = spaceReclaimed
    }
}

/// CreateVolume is used to create a new volume.
public struct CreateVolume: Codable, Hashable, Sendable {
    public var name: String
    public var driver: String?
    public var driverOpts: [String: String]?
    public var labels: [String: String]?

    public init(
        name: String,
        driver: String? = nil,
        driverOpts: [String: String]? = nil,
        labels: [String: String]? = nil
    ) {
        self.name = name
        self.driver = driver
        self.driverOpts = driverOpts
        self.labels = labels
    }
}

/// VolumeUsage represents per-volume usage details returned by GET /volumes/{name}/usage.
public struct VolumeUsage: Codable, Hashable, Sendable {
    public var inUse: Bool
    public var containers: [String]

    public init(inUse: Bool, containers: [String] = []) {
        self.inUse = inUse
        self.containers = containers
    }
}

/// VolumeSizeInfo represents size information for a single volume.
public struct VolumeSizeInfo: Codable, Hashable, Sendable {
    public var name: String
    public var size: Int64
    public var refCount: Int64

    public init(name: String, size: Int64, refCount: Int64) {
        self.name = name
        self.size = size
        self.refCount = refCount
    }
}

/// VolumeListPage is the page envelope returned by ``GET /environments/{id}/volumes``.
public struct VolumeListPage: Decodable, Sendable {
    public var success: Bool
    public var data: [Volume]
    public var counts: VolumeUsageCounts
    public var pagination: PaginationResponse
}
