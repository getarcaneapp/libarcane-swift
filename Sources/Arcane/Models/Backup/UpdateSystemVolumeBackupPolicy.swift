import Foundation

public struct UpdateSystemVolumeBackupPolicy: Codable, Hashable, Sendable, Identifiable {
  public var id: String?
  public var enabled: Bool
  public var schedule: String
  public var retentionCount: Int
  public var stopContainers: Bool?
  public var localEnabled: Bool
  public var s3Enabled: Bool
  public var s3DestinationId: String?
  public var selectionMode: String
  public var volumeNames: [String]
  public var ignoreAnonymous: Bool

  public init(
    id: String? = nil,
    enabled: Bool,
    schedule: String,
    retentionCount: Int,
    stopContainers: Bool? = nil,
    localEnabled: Bool,
    s3Enabled: Bool,
    s3DestinationId: String? = nil,
    selectionMode: String,
    volumeNames: [String],
    ignoreAnonymous: Bool
  ) {
    self.id = id
    self.enabled = enabled
    self.schedule = schedule
    self.retentionCount = retentionCount
    self.stopContainers = stopContainers
    self.localEnabled = localEnabled
    self.s3Enabled = s3Enabled
    self.s3DestinationId = s3DestinationId
    self.selectionMode = selectionMode
    self.volumeNames = volumeNames
    self.ignoreAnonymous = ignoreAnonymous
  }
}
