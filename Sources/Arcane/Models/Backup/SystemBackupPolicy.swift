import Foundation

public struct SystemBackupPolicy: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var enabled: Bool
  public var schedule: String
  public var retentionCount: Int
  public var localEnabled: Bool
  public var s3Enabled: Bool
  public var s3DestinationId: String?
  public var s3DestinationName: String?
  public var lastRun: SystemBackupRun?

  public init(
    id: String,
    enabled: Bool,
    schedule: String,
    retentionCount: Int,
    localEnabled: Bool,
    s3Enabled: Bool,
    s3DestinationId: String? = nil,
    s3DestinationName: String? = nil,
    lastRun: SystemBackupRun? = nil
  ) {
    self.id = id
    self.enabled = enabled
    self.schedule = schedule
    self.retentionCount = retentionCount
    self.localEnabled = localEnabled
    self.s3Enabled = s3Enabled
    self.s3DestinationId = s3DestinationId
    self.s3DestinationName = s3DestinationName
    self.lastRun = lastRun
  }
}
