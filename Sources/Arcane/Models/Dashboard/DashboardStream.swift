import Foundation

/// Event kinds emitted by the aggregated dashboard stream
/// (``DashboardService/stream(debugAllGood:)``).
public enum DashboardStreamEventType: Hashable, Sendable, Codable {
    case snapshot
    case pending
    case heartbeat
    case error
    case unknown(String)

    public var rawValue: String {
        switch self {
        case .snapshot: return "snapshot"
        case .pending: return "pending"
        case .heartbeat: return "heartbeat"
        case .error: return "error"
        case let .unknown(value): return value
        }
    }

    public init(rawValue: String) {
        switch rawValue {
        case "snapshot": self = .snapshot
        case "pending": self = .pending
        case "heartbeat": self = .heartbeat
        case "error": self = .error
        default: self = .unknown(rawValue)
        }
    }

    public init(from decoder: Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// Classified failure reasons carried by dashboard stream `error` events.
/// The backend omits the field for unclassified errors.
public enum DashboardStreamErrorCode: Hashable, Sendable, Codable {
    /// The remote agent runs an older Arcane without the dashboard endpoint.
    case agentIncompatible
    /// Transport/network failure reaching the agent.
    case unreachable
    case unknown(String)

    public var rawValue: String {
        switch self {
        case .agentIncompatible: return "agent_incompatible"
        case .unreachable: return "unreachable"
        case let .unknown(value): return value
        }
    }

    public init(rawValue: String) {
        switch rawValue {
        case "agent_incompatible": self = .agentIncompatible
        case "unreachable": self = .unreachable
        default: self = .unknown(rawValue)
        }
    }

    public init(from decoder: Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// One line of the aggregated dashboard NDJSON stream. Snapshot payloads have
/// their container/image table rows trimmed server-side — only the aggregate
/// counts, action items, settings, and version info are populated.
public struct DashboardStreamEvent: Codable, Hashable, Sendable {
    public var type: DashboardStreamEventType
    public var environmentID: String?
    public var snapshot: DashboardSnapshot?
    public var error: String?
    public var errorCode: DashboardStreamErrorCode?
    public var timestamp: Date

    public enum CodingKeys: String, CodingKey {
        case type
        case environmentID = "environmentId"
        case snapshot
        case error
        case errorCode
        case timestamp
    }

    public init(
        type: DashboardStreamEventType,
        environmentID: String? = nil,
        snapshot: DashboardSnapshot? = nil,
        error: String? = nil,
        errorCode: DashboardStreamErrorCode? = nil,
        timestamp: Date
    ) {
        self.type = type
        self.environmentID = environmentID
        self.snapshot = snapshot
        self.error = error
        self.errorCode = errorCode
        self.timestamp = timestamp
    }

    /// Environment the event applies to; a missing/empty ID (local environment)
    /// normalizes to ``EnvironmentID/localDocker``. Meaningless for heartbeats.
    public var resolvedEnvironmentID: String {
        guard let environmentID, !environmentID.isEmpty else {
            return EnvironmentID.localDocker.rawValue
        }
        return environmentID
    }
}
