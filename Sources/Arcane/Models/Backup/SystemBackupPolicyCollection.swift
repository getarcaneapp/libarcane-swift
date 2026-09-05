import Foundation

public struct SystemBackupPolicyCollection: Codable, Hashable, Sendable {
  public var policies: [SystemBackupPolicy]
  public var recoveryKeyStored: Bool

  public init(
    policies: [SystemBackupPolicy],
    recoveryKeyStored: Bool
  ) {
    self.policies = policies
    self.recoveryKeyStored = recoveryKeyStored
  }
}
