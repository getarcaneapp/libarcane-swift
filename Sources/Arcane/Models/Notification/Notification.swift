import Foundation

/// Identifiers for notification providers.
public enum NotificationProvider: String, Codable, Hashable, Sendable {
    case discord
    case email
    case telegram
    case signal
    case slack
    case ntfy
    case pushover
    case matrix
    case generic
}

public struct NotificationSettings: Codable, Hashable, Sendable, Identifiable {
    public var id: UInt
    public var provider: NotificationProvider
    public var enabled: Bool
    public var config: [String: JSONValue]

    public init(
        id: UInt,
        provider: NotificationProvider,
        enabled: Bool,
        config: [String: JSONValue] = [:]
    ) {
        self.id = id
        self.provider = provider
        self.enabled = enabled
        self.config = config
    }
}

public struct UpdateNotificationSettings: Codable, Hashable, Sendable {
    public var provider: NotificationProvider
    public var enabled: Bool
    public var config: [String: JSONValue]

    public init(
        provider: NotificationProvider,
        enabled: Bool,
        config: [String: JSONValue] = [:]
    ) {
        self.provider = provider
        self.enabled = enabled
        self.config = config
    }
}

public struct AppriseSettings: Codable, Hashable, Sendable, Identifiable {
    public var id: UInt
    public var apiUrl: String
    public var enabled: Bool
    public var imageUpdateTag: String
    public var containerUpdateTag: String

    public init(
        id: UInt,
        apiUrl: String,
        enabled: Bool,
        imageUpdateTag: String,
        containerUpdateTag: String
    ) {
        self.id = id
        self.apiUrl = apiUrl
        self.enabled = enabled
        self.imageUpdateTag = imageUpdateTag
        self.containerUpdateTag = containerUpdateTag
    }
}

public struct UpdateAppriseSettings: Codable, Hashable, Sendable {
    public var apiUrl: String
    public var enabled: Bool
    public var imageUpdateTag: String
    public var containerUpdateTag: String

    public init(
        apiUrl: String,
        enabled: Bool,
        imageUpdateTag: String,
        containerUpdateTag: String
    ) {
        self.apiUrl = apiUrl
        self.enabled = enabled
        self.imageUpdateTag = imageUpdateTag
        self.containerUpdateTag = containerUpdateTag
    }
}

public enum NotificationTestType: String, Codable, Hashable, Sendable {
    case simple
    case imageUpdate = "image-update"
    case batchImageUpdate = "batch-image-update"
    case vulnerabilityFound = "vulnerability-found"
    case pruneReport = "prune-report"
    case autoHeal = "auto-heal"
}

public enum NotificationDispatchKind: String, Codable, Hashable, Sendable {
    case imageUpdate = "image_update"
    case batchImageUpdate = "batch_image_update"
    case containerUpdate = "container_update"
    case vulnerabilityFound = "vulnerability_found"
    case pruneReport = "prune_report"
    case autoHeal = "auto_heal"
}

public struct NotificationDispatchImageUpdate: Codable, Hashable, Sendable {
    public var imageRef: String
    public var updateInfo: JSONValue

    public init(imageRef: String, updateInfo: JSONValue) {
        self.imageRef = imageRef
        self.updateInfo = updateInfo
    }
}

public struct NotificationDispatchBatchImageUpdate: Codable, Hashable, Sendable {
    public var updates: [String: JSONValue]

    public init(updates: [String: JSONValue]) {
        self.updates = updates
    }
}

public struct NotificationDispatchContainerUpdate: Codable, Hashable, Sendable {
    public var containerName: String
    public var imageRef: String
    public var oldDigest: String?
    public var newDigest: String?

    public init(
        containerName: String,
        imageRef: String,
        oldDigest: String? = nil,
        newDigest: String? = nil
    ) {
        self.containerName = containerName
        self.imageRef = imageRef
        self.oldDigest = oldDigest
        self.newDigest = newDigest
    }
}

public struct NotificationDispatchVulnerabilityFound: Codable, Hashable, Sendable {
    public var cveId: String
    public var cveLink: String
    public var severity: String
    public var imageName: String
    public var fixedVersion: String?
    public var pkgName: String?
    public var installedVersion: String?

    public init(
        cveId: String,
        cveLink: String,
        severity: String,
        imageName: String,
        fixedVersion: String? = nil,
        pkgName: String? = nil,
        installedVersion: String? = nil
    ) {
        self.cveId = cveId
        self.cveLink = cveLink
        self.severity = severity
        self.imageName = imageName
        self.fixedVersion = fixedVersion
        self.pkgName = pkgName
        self.installedVersion = installedVersion
    }
}

public struct NotificationDispatchPruneReport: Codable, Hashable, Sendable {
    public var result: JSONValue

    public init(result: JSONValue) {
        self.result = result
    }
}

public struct NotificationDispatchAutoHeal: Codable, Hashable, Sendable {
    public var containerName: String
    public var containerId: String

    public init(containerName: String, containerId: String) {
        self.containerName = containerName
        self.containerId = containerId
    }
}

public struct NotificationDispatchRequest: Codable, Hashable, Sendable {
    public var kind: NotificationDispatchKind
    public var imageUpdate: NotificationDispatchImageUpdate?
    public var batchImageUpdate: NotificationDispatchBatchImageUpdate?
    public var containerUpdate: NotificationDispatchContainerUpdate?
    public var vulnerabilityFound: NotificationDispatchVulnerabilityFound?
    public var pruneReport: NotificationDispatchPruneReport?
    public var autoHeal: NotificationDispatchAutoHeal?

    public init(
        kind: NotificationDispatchKind,
        imageUpdate: NotificationDispatchImageUpdate? = nil,
        batchImageUpdate: NotificationDispatchBatchImageUpdate? = nil,
        containerUpdate: NotificationDispatchContainerUpdate? = nil,
        vulnerabilityFound: NotificationDispatchVulnerabilityFound? = nil,
        pruneReport: NotificationDispatchPruneReport? = nil,
        autoHeal: NotificationDispatchAutoHeal? = nil
    ) {
        self.kind = kind
        self.imageUpdate = imageUpdate
        self.batchImageUpdate = batchImageUpdate
        self.containerUpdate = containerUpdate
        self.vulnerabilityFound = vulnerabilityFound
        self.pruneReport = pruneReport
        self.autoHeal = autoHeal
    }
}
