import Foundation

public struct DiscoverSystemBackupsRequest: Codable, Hashable, Sendable {
  public var s3DestinationId: String
  public var recoveryKey: String

  public init(
    s3DestinationId: String,
    recoveryKey: String
  ) {
    self.s3DestinationId = s3DestinationId
    self.recoveryKey = recoveryKey
  }
}
