import Foundation

/// Image update availability info attached to image and container summaries.
public struct ImageUpdateInfo: Codable, Hashable, Sendable {
  public var hasUpdate: Bool
  public var updateType: String
  public var currentVersion: String
  public var latestVersion: String
  public var currentDigest: String
  public var latestDigest: String
  /// Optional so responses from servers that omit the timestamp still decode.
  public var checkTime: Date?
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
    checkTime: Date? = nil,
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

extension ImageUpdateInfo {
  /// True when this inline info carries an actual check result — not just
  /// struct zero-values. Servers attach a default-initialized `updateInfo`
  /// to images that simply haven't been scanned yet; use this to avoid
  /// treating those as "up to date".
  public var hasCheckResult: Bool {
    hasUpdate
      || !error.isEmpty
      || !currentVersion.isEmpty
      || !currentDigest.isEmpty
      || !latestDigest.isEmpty
  }

  /// Bridges the inline/persisted info shape into the check-endpoint
  /// response shape (`ImageUpdateResponse`) so clients can consume a single
  /// model regardless of which endpoint produced the data.
  public var asUpdateResponse: ImageUpdateResponse {
    ImageUpdateResponse(
      hasUpdate: hasUpdate,
      updateType: updateType,
      currentVersion: currentVersion,
      latestVersion: latestVersion.isEmpty ? nil : latestVersion,
      currentDigest: currentDigest.isEmpty ? nil : currentDigest,
      latestDigest: latestDigest.isEmpty ? nil : latestDigest,
      checkTime: checkTime,
      responseTimeMs: responseTimeMs,
      error: error.isEmpty ? nil : error,
      authMethod: authMethod,
      authUsername: authUsername,
      authRegistry: authRegistry,
      usedCredential: usedCredential
    )
  }
}
