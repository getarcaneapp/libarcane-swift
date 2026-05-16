import Foundation

/// Image update availability info attached to image and container summaries.
public struct ImageUpdateInfo: Codable, Hashable, Sendable {
    public var hasUpdate: Bool
    public var updateType: String
    public var currentVersion: String
    public var latestVersion: String
    public var currentDigest: String
    public var latestDigest: String
    public var checkTime: Date
    public var responseTimeMs: Int
    public var error: String
    public var authMethod: String?
    public var authUsername: String?
    public var authRegistry: String?
    public var usedCredential: Bool?

    public init(
        hasUpdate: Bool = false,
        updateType: String = "",
        currentVersion: String = "",
        latestVersion: String = "",
        currentDigest: String = "",
        latestDigest: String = "",
        checkTime: Date = Date(),
        responseTimeMs: Int = 0,
        error: String = "",
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
