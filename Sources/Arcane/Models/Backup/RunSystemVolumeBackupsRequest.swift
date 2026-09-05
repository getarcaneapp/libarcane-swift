import Foundation

public struct RunSystemVolumeBackupsRequest: Codable, Hashable, Sendable {
  public var policyId: String?
  public var custom: SystemVolumeBackupCustomRun?

  public init(
    policyId: String? = nil,
    custom: SystemVolumeBackupCustomRun? = nil
  ) {
    self.policyId = policyId
    self.custom = custom
  }
}
