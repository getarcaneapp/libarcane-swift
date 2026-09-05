import Foundation

public struct DeleteSystemBackupRequest: Codable, Hashable, Sendable {
  public var recoveryKey: String?

  public init(
    recoveryKey: String? = nil
  ) {
    self.recoveryKey = recoveryKey
  }
}
