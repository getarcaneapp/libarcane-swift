import Foundation

public struct VolumeBackupPolicy: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var volumeName: String
  public var enabled: Bool
  public var schedule: String
  public var retentionCount: Int
  public var stopContainers: Bool
  public var localEnabled: Bool
  public var s3Enabled: Bool
  public var s3DestinationId: String?
  public var s3DestinationName: String?
  public var s3Available: Bool
  public var s3Bucket: String?
  public var lastRun: BackupEntry?

  public init(
    id: String,
    volumeName: String,
    enabled: Bool,
    schedule: String,
    retentionCount: Int,
    stopContainers: Bool,
    localEnabled: Bool,
    s3Enabled: Bool,
    s3DestinationId: String? = nil,
    s3DestinationName: String? = nil,
    s3Available: Bool,
    s3Bucket: String? = nil,
    lastRun: BackupEntry? = nil
  ) {
    self.id = id
    self.volumeName = volumeName
    self.enabled = enabled
    self.schedule = schedule
    self.retentionCount = retentionCount
    self.stopContainers = stopContainers
    self.localEnabled = localEnabled
    self.s3Enabled = s3Enabled
    self.s3DestinationId = s3DestinationId
    self.s3DestinationName = s3DestinationName
    self.s3Available = s3Available
    self.s3Bucket = s3Bucket
    self.lastRun = lastRun
  }
}
