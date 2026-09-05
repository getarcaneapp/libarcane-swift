import Foundation

/// BackupEntry represents a single volume backup record.
public struct BackupEntry: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var volumeName: String
  public var size: Int64
  public var createdAt: String
  public var activityID: String?
  public var status: String?
  public var trigger: String?
  public var destination: String?
  public var format: String?
  public var localSnapshotId: String?
  public var remoteSnapshotId: String?
  public var s3DestinationId: String?
  public var s3DestinationName: String?
  public var policyId: String?
  public var error: String?
  public var type: String?


  public init(
    id: String,
    volumeName: String,
    size: Int64,
    createdAt: String,
    activityID: String? = nil
  ) {
    self.id = id
    self.volumeName = volumeName
    self.size = size
    self.createdAt = createdAt
    self.activityID = activityID
  }

  private enum CodingKeys: String, CodingKey {
    case id, volumeName, size, createdAt
    case activityID = "activityId"
    case status, trigger, destination, format, localSnapshotId, remoteSnapshotId, s3DestinationId, s3DestinationName, policyId, error, type
  }
}

/// VolumeBackupListPage is the page envelope returned by ``GET volumes/{name}/backups``.
public struct VolumeBackupListPage: Decodable, Sendable {
  public var success: Bool
  public var data: [BackupEntry]
  public var pagination: PaginationResponse
  public var warnings: [String]?
}

/// BackupHasPath is the response for the ``has-path`` lookup.
public struct BackupHasPath: Codable, Hashable, Sendable {
  public var exists: Bool

  public init(exists: Bool) {
    self.exists = exists
  }
}

/// RestoreBackupFilesRequest is the body for the partial restore endpoint.
public struct RestoreBackupFilesRequest: Codable, Hashable, Sendable {
  public var paths: [String]
  public var selectAll: Bool?
  public var search: String?

  public init(paths: [String] = [], selectAll: Bool? = nil, search: String? = nil) {
    self.selectAll = selectAll
    self.search = search
    self.paths = paths
  }
}
