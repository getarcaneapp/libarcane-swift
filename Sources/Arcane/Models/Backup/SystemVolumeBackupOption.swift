import Foundation

public struct SystemVolumeBackupOption: Codable, Hashable, Sendable {
  public var name: String
  public var anonymous: Bool
  public var available: Bool

  public init(
    name: String,
    anonymous: Bool,
    available: Bool
  ) {
    self.name = name
    self.anonymous = anonymous
    self.available = available
  }
}
