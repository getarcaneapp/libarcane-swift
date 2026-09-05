import Foundation

public struct UpdateSystemVolumeBackupPolicies: Codable, Hashable, Sendable {
  public var policies: [UpdateSystemVolumeBackupPolicy]

  public init(
    policies: [UpdateSystemVolumeBackupPolicy]
  ) {
    self.policies = policies
  }
}
