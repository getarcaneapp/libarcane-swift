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

/// Result of a system-level container batch action (start/stop/etc.).
public struct SystemContainerActionResult: Codable, Hashable, Sendable {
    public var started: [String]?
    public var stopped: [String]?
    public var failed: [String]?
    public var success: Bool
    public var errors: [String]?

    public init(
        started: [String]? = nil,
        stopped: [String]? = nil,
        failed: [String]? = nil,
        success: Bool = false,
        errors: [String]? = nil
    ) {
        self.started = started
        self.stopped = stopped
        self.failed = failed
        self.success = success
        self.errors = errors
    }
}
