import Foundation

public struct SystemVolumeBackupPolicyCollection: Codable, Hashable, Sendable {
  public var policies: [SystemVolumeBackupPolicy]

  public init(
    policies: [SystemVolumeBackupPolicy]
  ) {
    self.policies = policies
  }
}
