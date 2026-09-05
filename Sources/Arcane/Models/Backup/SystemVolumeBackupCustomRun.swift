import Foundation

public struct SystemVolumeBackupCustomRun: Codable, Hashable, Sendable {
  public var destination: String
  public var s3DestinationId: String?
  public var stopContainers: Bool
  public var selectionMode: String
  public var volumeNames: [String]
  public var ignoreAnonymous: Bool

  public init(
    destination: String,
    s3DestinationId: String? = nil,
    stopContainers: Bool,
    selectionMode: String,
    volumeNames: [String],
    ignoreAnonymous: Bool
  ) {
    self.destination = destination
    self.s3DestinationId = s3DestinationId
    self.stopContainers = stopContainers
    self.selectionMode = selectionMode
    self.volumeNames = volumeNames
    self.ignoreAnonymous = ignoreAnonymous
  }
}
