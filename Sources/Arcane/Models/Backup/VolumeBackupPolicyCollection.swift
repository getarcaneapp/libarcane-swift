import Foundation

public struct VolumeBackupPolicyCollection: Codable, Hashable, Sendable {
  public var policies: [VolumeBackupPolicy]
  public var s3Available: Bool

  public init(
    policies: [VolumeBackupPolicy],
    s3Available: Bool
  ) {
    self.policies = policies
    self.s3Available = s3Available
  }
}
