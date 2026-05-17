import Foundation

/// Detailed application version information returned by `/app-version` and
/// `/environments/{id}/version`.
public struct VersionInfo: Codable, Hashable, Sendable {
    public var currentVersion: String
    public var currentTag: String?
    public var currentDigest: String?
    public var revision: String
    public var shortRevision: String
    public var goVersion: String
    public var enabledFeatures: [String]?
    public var buildTime: String?
    public var displayVersion: String
    public var isSemverVersion: Bool
    public var newestVersion: String?
    public var newestDigest: String?
    public var updateAvailable: Bool
    public var releaseUrl: String?
    public var releaseNotes: String?
    public var releasedAt: String?

    public init(
        currentVersion: String,
        currentTag: String? = nil,
        currentDigest: String? = nil,
        revision: String,
        shortRevision: String,
        goVersion: String,
        enabledFeatures: [String]? = nil,
        buildTime: String? = nil,
        displayVersion: String,
        isSemverVersion: Bool,
        newestVersion: String? = nil,
        newestDigest: String? = nil,
        updateAvailable: Bool,
        releaseUrl: String? = nil,
        releaseNotes: String? = nil,
        releasedAt: String? = nil
    ) {
        self.currentVersion = currentVersion
        self.currentTag = currentTag
        self.currentDigest = currentDigest
        self.revision = revision
        self.shortRevision = shortRevision
        self.goVersion = goVersion
        self.enabledFeatures = enabledFeatures
        self.buildTime = buildTime
        self.displayVersion = displayVersion
        self.isSemverVersion = isSemverVersion
        self.newestVersion = newestVersion
        self.newestDigest = newestDigest
        self.updateAvailable = updateAvailable
        self.releaseUrl = releaseUrl
        self.releaseNotes = releaseNotes
        self.releasedAt = releasedAt
    }
}

/// Simplified version-check response from `/version`.
public struct VersionCheck: Codable, Hashable, Sendable {
    public var currentVersion: String
    public var newestVersion: String?
    public var updateAvailable: Bool
    public var releaseUrl: String?

    public init(
        currentVersion: String,
        newestVersion: String? = nil,
        updateAvailable: Bool,
        releaseUrl: String? = nil
    ) {
        self.currentVersion = currentVersion
        self.newestVersion = newestVersion
        self.updateAvailable = updateAvailable
        self.releaseUrl = releaseUrl
    }
}
