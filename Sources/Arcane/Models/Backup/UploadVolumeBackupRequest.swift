import Foundation

public struct UploadVolumeBackupRequest: Codable, Hashable, Sendable {
  public var s3DestinationId: String

  public init(
    s3DestinationId: String
  ) {
    self.s3DestinationId = s3DestinationId
  }
}
