import Foundation

public enum ActivityStatus: Hashable, Sendable, Codable {
  case queued
  case running
  case success
  case failed
  case cancelled
  case unknown(String)

  public var rawValue: String {
    switch self {
    case .queued: return "queued"
    case .running: return "running"
    case .success: return "success"
    case .failed: return "failed"
    case .cancelled: return "cancelled"
    case .unknown(let value): return value
    }
  }

  public init(rawValue: String) {
    switch rawValue {
    case "queued": self = .queued
    case "running": self = .running
    case "success": self = .success
    case "failed": self = .failed
    case "cancelled": self = .cancelled
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

public enum ActivityType: Hashable, Sendable, Codable {
  case imagePull
  case imageBuild
  case imageUpdateCheck
  case projectPull
  case projectBuild
  case projectDeploy
  case projectRedeploy
  case projectDown
  case projectRestart
  case projectDestroy
  case containerStart
  case containerStop
  case containerRestart
  case containerRedeploy
  case containerDelete
  case vulnerabilityScan
  case autoUpdate
  case systemPrune
  case resourceAction
  case unknown(String)

  public var rawValue: String {
    switch self {
    case .imagePull: return "image_pull"
    case .imageBuild: return "image_build"
    case .imageUpdateCheck: return "image_update_check"
    case .projectPull: return "project_pull"
    case .projectBuild: return "project_build"
    case .projectDeploy: return "project_deploy"
    case .projectRedeploy: return "project_redeploy"
    case .projectDown: return "project_down"
    case .projectRestart: return "project_restart"
    case .projectDestroy: return "project_destroy"
    case .containerStart: return "container_start"
    case .containerStop: return "container_stop"
    case .containerRestart: return "container_restart"
    case .containerRedeploy: return "container_redeploy"
    case .containerDelete: return "container_delete"
    case .vulnerabilityScan: return "vulnerability_scan"
    case .autoUpdate: return "auto_update"
    case .systemPrune: return "system_prune"
    case .resourceAction: return "resource_action"
    case .unknown(let value): return value
    }
  }

  private static let rawValueMap: [String: ActivityType] = [
    "image_pull": .imagePull,
    "image_build": .imageBuild,
    "image_update_check": .imageUpdateCheck,
    "project_pull": .projectPull,
    "project_build": .projectBuild,
    "project_deploy": .projectDeploy,
    "project_redeploy": .projectRedeploy,
    "project_down": .projectDown,
    "project_restart": .projectRestart,
    "project_destroy": .projectDestroy,
    "container_start": .containerStart,
    "container_stop": .containerStop,
    "container_restart": .containerRestart,
    "container_redeploy": .containerRedeploy,
    "container_delete": .containerDelete,
    "vulnerability_scan": .vulnerabilityScan,
    "auto_update": .autoUpdate,
    "system_prune": .systemPrune,
    "resource_action": .resourceAction,
  ]

  public init(rawValue: String) {
    self = ActivityType.rawValueMap[rawValue] ?? .unknown(rawValue)
  }

  public init(from decoder: Decoder) throws {
    self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

public enum ActivityMessageLevel: Hashable, Sendable, Codable {
  case info
  case warning
  case error
  case success
  case unknown(String)

  public var rawValue: String {
    switch self {
    case .info: return "info"
    case .warning: return "warning"
    case .error: return "error"
    case .success: return "success"
    case .unknown(let value): return value
    }
  }

  public init(rawValue: String) {
    switch rawValue {
    case "info": self = .info
    case "warning": self = .warning
    case "error": self = .error
    case "success": self = .success
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

public enum ActivityStreamEventType: Hashable, Sendable, Codable {
  case snapshot
  case activity
  case message
  case missed
  case error
  case heartbeat
  case unknown(String)

  public var rawValue: String {
    switch self {
    case .snapshot: return "snapshot"
    case .activity: return "activity"
    case .message: return "message"
    case .missed: return "missed"
    case .error: return "error"
    case .heartbeat: return "heartbeat"
    case .unknown(let value): return value
    }
  }

  public init(rawValue: String) {
    switch rawValue {
    case "snapshot": self = .snapshot
    case "activity": self = .activity
    case "message": self = .message
    case "missed": self = .missed
    case "error": self = .error
    case "heartbeat": self = .heartbeat
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

public struct ActivityStartedBy: Codable, Hashable, Sendable {
  public var userId: String?
  public var username: String
  public var displayName: String?

  public init(userId: String? = nil, username: String, displayName: String? = nil) {
    self.userId = userId
    self.username = username
    self.displayName = displayName
  }
}

public struct Activity: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var environmentID: String
  public var sourceEnvironmentID: String?
  public var sourceEnvironmentName: String?
  public var type: ActivityType
  public var status: ActivityStatus
  public var resourceType: String?
  public var resourceID: String?
  public var resourceName: String?
  public var progress: Int?
  public var step: String
  public var latestMessage: String
  public var startedBy: ActivityStartedBy?
  public var startedAt: Date
  public var endedAt: Date?
  public var durationMs: Int64?
  public var error: String?
  public var metadata: [String: JSONValue]?
  public var createdAt: Date
  public var updatedAt: Date?

  public enum CodingKeys: String, CodingKey {
    case id
    case environmentID = "environmentId"
    case sourceEnvironmentID = "sourceEnvironmentId"
    case sourceEnvironmentName
    case type
    case status
    case resourceType
    case resourceID = "resourceId"
    case resourceName
    case progress
    case step
    case latestMessage
    case startedBy
    case startedAt
    case endedAt
    case durationMs
    case error
    case metadata
    case createdAt
    case updatedAt
  }

  public init(
    id: String,
    environmentID: String,
    sourceEnvironmentID: String? = nil,
    sourceEnvironmentName: String? = nil,
    type: ActivityType,
    status: ActivityStatus,
    resourceType: String? = nil,
    resourceID: String? = nil,
    resourceName: String? = nil,
    progress: Int? = nil,
    step: String = "",
    latestMessage: String = "",
    startedBy: ActivityStartedBy? = nil,
    startedAt: Date,
    endedAt: Date? = nil,
    durationMs: Int64? = nil,
    error: String? = nil,
    metadata: [String: JSONValue]? = nil,
    createdAt: Date,
    updatedAt: Date? = nil
  ) {
    self.id = id
    self.environmentID = environmentID
    self.sourceEnvironmentID = sourceEnvironmentID
    self.sourceEnvironmentName = sourceEnvironmentName
    self.type = type
    self.status = status
    self.resourceType = resourceType
    self.resourceID = resourceID
    self.resourceName = resourceName
    self.progress = progress
    self.step = step
    self.latestMessage = latestMessage
    self.startedBy = startedBy
    self.startedAt = startedAt
    self.endedAt = endedAt
    self.durationMs = durationMs
    self.error = error
    self.metadata = metadata
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

public struct ActivityMessage: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var activityID: String
  public var level: ActivityMessageLevel
  public var message: String
  public var payload: [String: JSONValue]?
  public var createdAt: Date

  public enum CodingKeys: String, CodingKey {
    case id
    case activityID = "activityId"
    case level
    case message
    case payload
    case createdAt
  }

  public init(
    id: String,
    activityID: String,
    level: ActivityMessageLevel,
    message: String,
    payload: [String: JSONValue]? = nil,
    createdAt: Date
  ) {
    self.id = id
    self.activityID = activityID
    self.level = level
    self.message = message
    self.payload = payload
    self.createdAt = createdAt
  }
}

public struct ActivityDetail: Codable, Hashable, Sendable {
  public var activity: Activity
  public var messages: [ActivityMessage]

  public init(activity: Activity, messages: [ActivityMessage] = []) {
    self.activity = activity
    self.messages = messages
  }
}

public struct ActivityStreamEvent: Codable, Hashable, Sendable {
  public var type: ActivityStreamEventType
  public var environmentID: String?
  public var activityID: String?
  public var activity: Activity?
  public var activities: [Activity]
  public var message: ActivityMessage?
  public var error: String?
  public var timestamp: Date

  public enum CodingKeys: String, CodingKey {
    case type
    case environmentID = "environmentId"
    case activityID = "activityId"
    case activity
    case activities
    case message
    case error
    case timestamp
  }

  public init(
    type: ActivityStreamEventType,
    environmentID: String? = nil,
    activityID: String? = nil,
    activity: Activity? = nil,
    activities: [Activity] = [],
    message: ActivityMessage? = nil,
    error: String? = nil,
    timestamp: Date
  ) {
    self.type = type
    self.environmentID = environmentID
    self.activityID = activityID
    self.activity = activity
    self.activities = activities
    self.message = message
    self.error = error
    self.timestamp = timestamp
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    type = try container.decode(ActivityStreamEventType.self, forKey: .type)
    environmentID = try container.decodeIfPresent(String.self, forKey: .environmentID)
    activityID = try container.decodeIfPresent(String.self, forKey: .activityID)
    activity = try container.decodeIfPresent(Activity.self, forKey: .activity)
    activities = try container.decodeIfPresent([Activity].self, forKey: .activities) ?? []
    message = try container.decodeIfPresent(ActivityMessage.self, forKey: .message)
    error = try container.decodeIfPresent(String.self, forKey: .error)
    timestamp = try container.decode(Date.self, forKey: .timestamp)
  }
}

public struct ClearActivityHistoryResult: Codable, Hashable, Sendable {
  public var deleted: Int64

  public init(deleted: Int64) {
    self.deleted = deleted
  }
}
