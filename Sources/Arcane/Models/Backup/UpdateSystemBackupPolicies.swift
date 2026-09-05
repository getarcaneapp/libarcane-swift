import Foundation

public struct UpdateSystemBackupPolicies: Codable, Hashable, Sendable {
  public var policies: [UpdateSystemBackupPolicy]

  public init(
    policies: [UpdateSystemBackupPolicy]
  ) {
    self.policies = policies
  }
}
