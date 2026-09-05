import Foundation

public struct BackupHistoryEntry: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var size: Int64
  public var createdAt: Date
  public var status: String
  public var trigger: String
  public var destination: String
  public var format: String?
  public var localSnapshotId: String?
  public var remoteSnapshotId: String?
  public var s3DestinationId: String?
  public var s3DestinationName: String?
  public var policyId: String?
  public var error: String?
  public var type: String
  public var resourceType: String
  public var resourceName: String

  public init(
    id: String,
    size: Int64,
    createdAt: Date,
    status: String,
    trigger: String,
    destination: String,
    format: String? = nil,
    localSnapshotId: String? = nil,
    remoteSnapshotId: String? = nil,
    s3DestinationId: String? = nil,
    s3DestinationName: String? = nil,
    policyId: String? = nil,
    error: String? = nil,
    type: String,
    resourceType: String,
    resourceName: String
  ) {
    self.id = id
    self.size = size
    self.createdAt = createdAt
    self.status = status
    self.trigger = trigger
    self.destination = destination
    self.format = format
    self.localSnapshotId = localSnapshotId
    self.remoteSnapshotId = remoteSnapshotId
    self.s3DestinationId = s3DestinationId
    self.s3DestinationName = s3DestinationName
    self.policyId = policyId
    self.error = error
    self.type = type
    self.resourceType = resourceType
    self.resourceName = resourceName
  }
}
