import Foundation

public struct SystemBackupRecoveryKeyStatus: Codable, Hashable, Sendable {
  public var configured: Bool

  public init(
    configured: Bool
  ) {
    self.configured = configured
  }
}
