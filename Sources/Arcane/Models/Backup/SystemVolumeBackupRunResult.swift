import Foundation

public struct SystemVolumeBackupRunResult: Codable, Hashable, Sendable {
  public var matched: Int
  public var succeeded: Int
  public var failed: Int
  public var skipped: Int
  public var failures: [SystemVolumeBackupFailure]

  public init(
    matched: Int,
    succeeded: Int,
    failed: Int,
    skipped: Int,
    failures: [SystemVolumeBackupFailure]
  ) {
    self.matched = matched
    self.succeeded = succeeded
    self.failed = failed
    self.skipped = skipped
    self.failures = failures
  }
}
