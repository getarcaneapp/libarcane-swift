import Foundation

/// Describes the project, container, or other consumer using an image.
public struct ImageUsedBy: Codable, Hashable, Sendable {
    public var type: String
    public var name: String
    public var id: String?

    public init(type: String, name: String, id: String? = nil) {
        self.type = type
        self.name = name
        self.id = id
    }
}

/// Image summary as returned by the list endpoint.
public struct ImageSummary: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var repoTags: [String]
    public var repoDigests: [String]
    public var created: Int64
    public var size: Int64
    public var virtualSize: Int64
    public var labels: [String: JSONValue]
    public var inUse: Bool
    public var usedBy: [ImageUsedBy]?
    public var repo: String
    public var tag: String
    public var updateInfo: ImageUpdateInfo?
    public var vulnerabilityScan: VulnerabilityScanSummary?

    public init(
        id: String,
        repoTags: [String] = [],
        repoDigests: [String] = [],
        created: Int64 = 0,
        size: Int64 = 0,
        virtualSize: Int64 = 0,
        labels: [String: JSONValue] = [:],
        inUse: Bool = false,
        usedBy: [ImageUsedBy]? = nil,
        repo: String = "",
        tag: String = "",
        updateInfo: ImageUpdateInfo? = nil,
        vulnerabilityScan: VulnerabilityScanSummary? = nil
    ) {
        self.id = id
        self.repoTags = repoTags
        self.repoDigests = repoDigests
        self.created = created
        self.size = size
        self.virtualSize = virtualSize
        self.labels = labels
        self.inUse = inUse
        self.usedBy = usedBy
        self.repo = repo
        self.tag = tag
        self.updateInfo = updateInfo
        self.vulnerabilityScan = vulnerabilityScan
    }
}

/// Result of an image prune operation.
public struct ImagePruneReport: Codable, Hashable, Sendable {
    public var imagesDeleted: [String]
    public var spaceReclaimed: Int64

    public init(imagesDeleted: [String] = [], spaceReclaimed: Int64 = 0) {
        self.imagesDeleted = imagesDeleted
        self.spaceReclaimed = spaceReclaimed
    }
}

/// Aggregate image usage counts for an environment.
public struct ImageUsageCounts: Codable, Hashable, Sendable {
    public var imagesInuse: Int
    public var imagesUnused: Int
    public var totalImages: Int
    public var totalImageSize: Int64

    public init(
        imagesInuse: Int = 0,
        imagesUnused: Int = 0,
        totalImages: Int = 0,
        totalImageSize: Int64 = 0
    ) {
        self.imagesInuse = imagesInuse
        self.imagesUnused = imagesUnused
        self.totalImages = totalImages
        self.totalImageSize = totalImageSize
    }
}

/// Result of a `docker load` operation.
public struct ImageLoadResult: Codable, Hashable, Sendable {
    public var stream: String

    public init(stream: String = "") {
        self.stream = stream
    }
}

/// Standardized NDJSON envelope for pull/build/deploy streams.
public struct ImageProgressDetail: Codable, Hashable, Sendable {
    public var current: Int64?
    public var total: Int64?

    public init(current: Int64? = nil, total: Int64? = nil) {
        self.current = current
        self.total = total
    }
}

/// A single progress event emitted by streaming image endpoints.
public struct ImageProgressEvent: Codable, Hashable, Sendable {
    public var type: String?
    public var phase: String?
    public var service: String?
    public var status: String?
    public var id: String?
    public var progressDetail: ImageProgressDetail?
    public var error: String?

    public init(
        type: String? = nil,
        phase: String? = nil,
        service: String? = nil,
        status: String? = nil,
        id: String? = nil,
        progressDetail: ImageProgressDetail? = nil,
        error: String? = nil
    ) {
        self.type = type
        self.phase = phase
        self.service = service
        self.status = status
        self.id = id
        self.progressDetail = progressDetail
        self.error = error
    }
}

/// Paginated list response for images.
public struct ImageListResponse: Decodable, Sendable {
    public var success: Bool
    public var data: [ImageSummary]
    public var pagination: PaginationResponse
}
