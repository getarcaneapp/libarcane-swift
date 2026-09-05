import Foundation

public struct BackupRunAccepted: Codable, Hashable, Sendable {
  public var activityId: String
  public var status: String

  public init(
    activityId: String,
    status: String
  ) {
    self.activityId = activityId
    self.status = status
  }
}
