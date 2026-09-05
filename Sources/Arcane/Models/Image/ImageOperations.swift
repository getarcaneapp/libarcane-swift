import Foundation

public struct ImageSearchResult: Codable, Hashable, Sendable, Identifiable {
  public var name: String
  public var description: String
  public var starCount: Int
  public var official: Bool
  public var automated: Bool
  public var id: String { name }
}

public struct ImageTagRequest: Codable, Hashable, Sendable {
  public var repository: String
  public var tag: String?

  public init(repository: String, tag: String? = nil) {
    self.repository = repository
    self.tag = tag
  }
}

public struct ImagePatchOptions: Codable, Hashable, Sendable {
  public var suffix: String?
  public var patchedTag: String?
  public var timeoutSeconds: Int?
  public var scanId: String?
  public var ignoreErrors: Bool?

  public init(
    suffix: String? = nil, patchedTag: String? = nil, timeoutSeconds: Int? = nil,
    scanId: String? = nil, ignoreErrors: Bool? = nil
  ) {
    self.suffix = suffix
    self.patchedTag = patchedTag
    self.timeoutSeconds = timeoutSeconds
    self.scanId = scanId
    self.ignoreErrors = ignoreErrors
  }
}

public struct ImagePatchRecord: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var environmentId: String
  public var originalImageId: String
  public var originalRef: String
  public var originalDigest: String?
  public var patchedRef: String
  public var mode: String
  public var status: String
  public var packagesUpdated: Int?
  public var error: String?
  public var activityId: String?
  public var durationMs: Int64?
  public var createdAt: Date
  public var updatedAt: Date?
}

public struct ImagePatchScanSummary: Codable, Hashable, Sendable {
  public var status: String
  public var fixableCount: Int
  public var totalCount: Int
  public var scanTime: Date
}

public struct ImagePatchTarget: Codable, Hashable, Sendable, Identifiable {
  public var imageId: String
  public var imageRef: String
  public var fixableCount: Int
  public var totalCount: Int
  public var scanTime: Date
  public var localOnly: Bool?
  public var lastPatch: ImagePatchRecord?
  public var lastPatchScan: ImagePatchScanSummary?
  public var id: String { imageId }
}
