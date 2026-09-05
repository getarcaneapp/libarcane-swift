import Foundation

public struct SystemVolumeBackupFailure: Codable, Hashable, Sendable {
  public var volumeName: String
  public var error: String

  public init(
    volumeName: String,
    error: String
  ) {
    self.volumeName = volumeName
    self.error = error
  }
}
