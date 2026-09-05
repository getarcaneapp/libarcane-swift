import Foundation

public struct RestoreSystemBackupRequest: Codable, Hashable, Sendable {
  public var recoveryKey: String

  public init(
    recoveryKey: String
  ) {
    self.recoveryKey = recoveryKey
  }
}
