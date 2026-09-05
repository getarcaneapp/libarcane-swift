import Foundation

public struct UpdateVolumeBackupPolicies: Codable, Hashable, Sendable {
  public var policies: [UpdateBackupPolicy]

  public init(
    policies: [UpdateBackupPolicy]
  ) {
    self.policies = policies
  }
}
