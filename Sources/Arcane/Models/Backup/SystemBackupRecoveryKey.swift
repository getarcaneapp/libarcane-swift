import Foundation

public struct SystemBackupRecoveryKey: Codable, Hashable, Sendable {
  public var recoveryKey: String

  public init(
    recoveryKey: String
  ) {
    self.recoveryKey = recoveryKey
  }
}
