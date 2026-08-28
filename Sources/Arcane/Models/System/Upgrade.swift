import Foundation

/// Result of the system upgrade-availability check.
public struct UpgradeCheckResult: Codable, Hashable, Sendable {
  public var canUpgrade: Bool
  public var error: Bool
  public var message: String

  public init(canUpgrade: Bool, error: Bool, message: String) {
    self.canUpgrade = canUpgrade
    self.error = error
    self.message = message
  }
}

/// Status of a fleet-wide update-all job.
public enum EnvironmentUpdateJobStatus: String, Codable, Hashable, Sendable {
  case running
  case pendingRestart = "pending_restart"
  case completed
  case failed
  /// Fallback for status values introduced by newer servers.
  case unknown

  public init(from decoder: Decoder) throws {
    let raw = try decoder.singleValueContainer().decode(String.self)
    self = Self(rawValue: raw) ?? .unknown
  }
}

/// Per-environment status within a fleet-wide update-all job.
public enum EnvironmentUpdateResultStatus: String, Codable, Hashable, Sendable {
  case pending
  case updating
  case updated
  case upToDate = "up_to_date"
  case triggered
  case skippedOffline = "skipped_offline"
  case failed
  /// Fallback for status values introduced by newer servers.
  case unknown

  public init(from decoder: Decoder) throws {
    let raw = try decoder.singleValueContainer().decode(String.self)
    self = Self(rawValue: raw) ?? .unknown
  }
}

/// Outcome of one environment inside a fleet-wide update-all job. The manager
/// itself appears as `environmentId == "0"` and is upgraded last.
public struct EnvironmentUpdateResult: Codable, Hashable, Sendable, Identifiable {
  public var environmentId: String
  public var environmentName: String
  public var status: EnvironmentUpdateResultStatus
  public var fromVersion: String?
  public var toVersion: String?
  public var error: String?

  public var id: String { environmentId }

  public init(
    environmentId: String,
    environmentName: String,
    status: EnvironmentUpdateResultStatus,
    fromVersion: String? = nil,
    toVersion: String? = nil,
    error: String? = nil
  ) {
    self.environmentId = environmentId
    self.environmentName = environmentName
    self.status = status
    self.fromVersion = fromVersion
    self.toVersion = toVersion
    self.error = error
  }
}

/// A fleet-wide Arcane update-all job: agents are upgraded first, then the
/// manager restarts (`pendingRestart`) and the job is finalized on next boot.
public struct EnvironmentUpdateJob: Codable, Hashable, Sendable {
  public var id: String
  public var createdAt: Date?
  public var updatedAt: Date?
  public var status: EnvironmentUpdateJobStatus
  public var userId: String?
  public var username: String?
  public var managerVersionAtStart: String?
  public var managerDigestAtStart: String?
  public var managerTargetVersion: String?
  public var results: [EnvironmentUpdateResult]?
  public var error: String?
  public var completedAt: Date?

  /// The manager's own row (`environmentId == "0"`), if present.
  public var managerResult: EnvironmentUpdateResult? {
    results?.first { $0.environmentId == "0" }
  }

  public var isTerminal: Bool { status == .completed || status == .failed }

  public init(
    id: String,
    createdAt: Date? = nil,
    updatedAt: Date? = nil,
    status: EnvironmentUpdateJobStatus,
    userId: String? = nil,
    username: String? = nil,
    managerVersionAtStart: String? = nil,
    managerDigestAtStart: String? = nil,
    managerTargetVersion: String? = nil,
    results: [EnvironmentUpdateResult]? = nil,
    error: String? = nil,
    completedAt: Date? = nil
  ) {
    self.id = id
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.status = status
    self.userId = userId
    self.username = username
    self.managerVersionAtStart = managerVersionAtStart
    self.managerDigestAtStart = managerDigestAtStart
    self.managerTargetVersion = managerTargetVersion
    self.results = results
    self.error = error
    self.completedAt = completedAt
  }
}

/// Result of a system-level container batch action (start/stop/etc.).
public struct SystemContainerActionResult: Codable, Hashable, Sendable {
  public var started: [String]?
  public var stopped: [String]?
  public var failed: [String]?
  public var success: Bool
  public var errors: [String]?
  public var activityID: String?

  public init(
    started: [String]? = nil,
    stopped: [String]? = nil,
    failed: [String]? = nil,
    success: Bool = false,
    errors: [String]? = nil,
    activityID: String? = nil
  ) {
    self.started = started
    self.stopped = stopped
    self.failed = failed
    self.success = success
    self.errors = errors
    self.activityID = activityID
  }

  private enum CodingKeys: String, CodingKey {
    case started, stopped, failed, success, errors
    case activityID = "activityId"
  }
}
