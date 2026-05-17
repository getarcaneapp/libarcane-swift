import Foundation

/// Options passed when triggering the updater (`POST .../updater/run`).
public struct UpdaterOptions: Codable, Hashable, Sendable {
    public var type: String?
    public var resourceIds: [String]?
    public var forceUpdate: Bool?
    public var dryRun: Bool?

    public init(
        type: String? = nil,
        resourceIds: [String]? = nil,
        forceUpdate: Bool? = nil,
        dryRun: Bool? = nil
    ) {
        self.type = type
        self.resourceIds = resourceIds
        self.forceUpdate = forceUpdate
        self.dryRun = dryRun
    }
}

/// Result for a single resource updated by the updater.
public struct UpdaterResourceResult: Codable, Hashable, Sendable {
    public var resourceId: String
    public var resourceName: String?
    public var resourceType: String
    public var status: String
    public var updateAvailable: Bool?
    public var updateApplied: Bool?
    public var oldImages: [String: String]?
    public var newImages: [String: String]?
    public var error: String?
    public var details: [String: JSONValue]?

    public init(
        resourceId: String,
        resourceName: String? = nil,
        resourceType: String,
        status: String,
        updateAvailable: Bool? = nil,
        updateApplied: Bool? = nil,
        oldImages: [String: String]? = nil,
        newImages: [String: String]? = nil,
        error: String? = nil,
        details: [String: JSONValue]? = nil
    ) {
        self.resourceId = resourceId
        self.resourceName = resourceName
        self.resourceType = resourceType
        self.status = status
        self.updateAvailable = updateAvailable
        self.updateApplied = updateApplied
        self.oldImages = oldImages
        self.newImages = newImages
        self.error = error
        self.details = details
    }
}

/// Overall result of an updater run.
public struct UpdaterResult: Codable, Hashable, Sendable {
    public var success: Bool?
    public var checked: Int
    public var updated: Int
    public var skipped: Int
    public var failed: Int
    public var startTime: String?
    public var endTime: String?
    public var duration: String
    public var items: [UpdaterResourceResult]

    public init(
        success: Bool? = nil,
        checked: Int = 0,
        updated: Int = 0,
        skipped: Int = 0,
        failed: Int = 0,
        startTime: String? = nil,
        endTime: String? = nil,
        duration: String = "",
        items: [UpdaterResourceResult] = []
    ) {
        self.success = success
        self.checked = checked
        self.updated = updated
        self.skipped = skipped
        self.failed = failed
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.items = items
    }
}

/// Live status of the updater.
public struct UpdaterStatus: Codable, Hashable, Sendable {
    public var updatingContainers: Int
    public var updatingProjects: Int
    public var containerIds: [String]
    public var projectIds: [String]

    public init(
        updatingContainers: Int = 0,
        updatingProjects: Int = 0,
        containerIds: [String] = [],
        projectIds: [String] = []
    ) {
        self.updatingContainers = updatingContainers
        self.updatingProjects = updatingProjects
        self.containerIds = containerIds
        self.projectIds = projectIds
    }
}

/// One row in the updater run history.
public struct AutoUpdateRecord: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var resourceId: String
    public var resourceType: String
    public var resourceName: String
    public var status: AutoUpdateRecordStatus
    public var startTime: Date
    public var endTime: Date?
    public var updateAvailable: Bool
    public var updateApplied: Bool
    public var oldImageVersions: [String: JSONValue]?
    public var newImageVersions: [String: JSONValue]?
    public var error: String?
    public var details: [String: JSONValue]?
    public var createdAt: Date
    public var updatedAt: Date?

    public init(
        id: String,
        resourceId: String,
        resourceType: String,
        resourceName: String,
        status: AutoUpdateRecordStatus,
        startTime: Date,
        endTime: Date? = nil,
        updateAvailable: Bool,
        updateApplied: Bool,
        oldImageVersions: [String: JSONValue]? = nil,
        newImageVersions: [String: JSONValue]? = nil,
        error: String? = nil,
        details: [String: JSONValue]? = nil,
        createdAt: Date,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.resourceId = resourceId
        self.resourceType = resourceType
        self.resourceName = resourceName
        self.status = status
        self.startTime = startTime
        self.endTime = endTime
        self.updateAvailable = updateAvailable
        self.updateApplied = updateApplied
        self.oldImageVersions = oldImageVersions
        self.newImageVersions = newImageVersions
        self.error = error
        self.details = details
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum AutoUpdateRecordStatus: String, Codable, Hashable, Sendable {
    case pending
    case checking
    case updating
    case completed
    case failed
    case skipped
}
