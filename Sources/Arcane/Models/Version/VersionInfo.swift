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

  /// True iff `enabledFeatures` advertises `mobile-push-v1`.
  public var supportsMobilePush: Bool {
    (enabledFeatures ?? []).contains { $0.lowercased() == mobilePushFeature }
  }

  public var supportsPost26MobileFeatures: Bool {
    guard isSemverVersion,
      let version = SemanticVersion(currentVersion)
    else {
      return false
    }
    return version >= SemanticVersion(major: 2, minor: 7, patch: 0)
  }
}

private struct SemanticVersion: Comparable {
  let major: Int
  let minor: Int
  let patch: Int

  init(major: Int, minor: Int, patch: Int) {
    self.major = major
    self.minor = minor
    self.patch = patch
  }

  init?(_ rawValue: String) {
    var value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    if value.hasPrefix("v") { value.removeFirst() }
    let core = value.split(separator: "+", maxSplits: 1)[0]
      .split(separator: "-", maxSplits: 1)[0]
    let components = core.split(separator: ".", omittingEmptySubsequences: false)
    guard components.count == 3,
      let major = Int(components[0]),
      let minor = Int(components[1]),
      let patch = Int(components[2]),
      major >= 0, minor >= 0, patch >= 0
    else {
      return nil
    }
    self.init(major: major, minor: minor, patch: patch)
  }

  static func < (lhs: Self, rhs: Self) -> Bool {
    if lhs.major != rhs.major { return lhs.major < rhs.major }
    if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
    return lhs.patch < rhs.patch
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
