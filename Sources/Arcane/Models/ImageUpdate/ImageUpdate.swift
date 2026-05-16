import Foundation

/// Result of an image update check.
public struct ImageUpdateResponse: Codable, Hashable, Sendable {
    public var hasUpdate: Bool
    public var updateType: String
    public var currentVersion: String
    public var latestVersion: String?
    public var currentDigest: String?
    public var latestDigest: String?
    public var checkTime: Date
    public var responseTimeMs: Int
    public var error: String?
    public var authMethod: String?
    public var authUsername: String?
    public var authRegistry: String?
    public var usedCredential: Bool?

    public init(
        hasUpdate: Bool = false,
        updateType: String = "",
        currentVersion: String = "",
        latestVersion: String? = nil,
        currentDigest: String? = nil,
        latestDigest: String? = nil,
        checkTime: Date = Date(),
        responseTimeMs: Int = 0,
        error: String? = nil,
        authMethod: String? = nil,
        authUsername: String? = nil,
        authRegistry: String? = nil,
        usedCredential: Bool? = nil
    ) {
        self.hasUpdate = hasUpdate
        self.updateType = updateType
        self.currentVersion = currentVersion
        self.latestVersion = latestVersion
        self.currentDigest = currentDigest
        self.latestDigest = latestDigest
        self.checkTime = checkTime
        self.responseTimeMs = responseTimeMs
        self.error = error
        self.authMethod = authMethod
        self.authUsername = authUsername
        self.authRegistry = authRegistry
        self.usedCredential = usedCredential
    }
}

/// Aggregate summary of image update status across an environment.
public struct ImageUpdateSummary: Codable, Hashable, Sendable {
    public var totalImages: Int
    public var imagesWithUpdates: Int
    public var digestUpdates: Int
    public var errorsCount: Int

    public init(
        totalImages: Int = 0,
        imagesWithUpdates: Int = 0,
        digestUpdates: Int = 0,
        errorsCount: Int = 0
    ) {
        self.totalImages = totalImages
        self.imagesWithUpdates = imagesWithUpdates
        self.digestUpdates = digestUpdates
        self.errorsCount = errorsCount
    }
}

/// Request body for the batch image update check endpoint.
public struct BatchImageUpdateRequest: Codable, Hashable, Sendable {
    public var imageRefs: [String]
    public var credentials: [ContainerRegistryCredential]?

    public init(imageRefs: [String], credentials: [ContainerRegistryCredential]? = nil) {
        self.imageRefs = imageRefs
        self.credentials = credentials
    }
}

/// Request body for the "check all images" endpoint.
public struct CheckAllImagesRequest: Codable, Hashable, Sendable {
    public var credentials: [ContainerRegistryCredential]?

    public init(credentials: [ContainerRegistryCredential]? = nil) {
        self.credentials = credentials
    }
}

/// Map keyed by image reference. Values may be null if the check failed.
public typealias ImageUpdateBatchResponse = [String: ImageUpdateResponse?]
