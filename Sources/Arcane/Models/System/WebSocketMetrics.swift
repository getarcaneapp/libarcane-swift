import Foundation

/// Stable identifiers for the different WebSocket connection kinds.
public enum WebSocketKind: String, Codable, Hashable, Sendable {
  case projectLogs = "project_logs"
  case containerLogs = "container_logs"
  case containerStats = "container_stats"
  case containerExec = "container_exec"
  case systemStats = "system_stats"
  case serviceLogs = "service_logs"
}

/// Description of a single active WebSocket connection on the server.
public struct WebSocketConnectionInfo: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var kind: String
  public var envId: String?
  public var resourceId: String?
  public var clientIp: String?
  public var userId: String?
  public var userAgent: String?
  public var startedAt: Date

  public init(
    id: String,
    kind: String,
    envId: String? = nil,
    resourceId: String? = nil,
    clientIp: String? = nil,
    userId: String? = nil,
    userAgent: String? = nil,
    startedAt: Date
  ) {
    self.id = id
    self.kind = kind
    self.envId = envId
    self.resourceId = resourceId
    self.clientIp = clientIp
    self.userId = userId
    self.userAgent = userAgent
    self.startedAt = startedAt
  }
}

/// Point-in-time snapshot of active WebSocket connection counts by kind.
public struct WebSocketMetricsSnapshot: Codable, Hashable, Sendable {
  public var projectLogsActive: Int64
  public var containerLogsActive: Int64
  public var containerStats: Int64
  public var containerExec: Int64
  public var systemStats: Int64
  public var serviceLogsActive: Int64

  public init(
    projectLogsActive: Int64,
    containerLogsActive: Int64,
    containerStats: Int64,
    containerExec: Int64,
    systemStats: Int64,
    serviceLogsActive: Int64
  ) {
    self.projectLogsActive = projectLogsActive
    self.containerLogsActive = containerLogsActive
    self.containerStats = containerStats
    self.containerExec = containerExec
    self.systemStats = systemStats
    self.serviceLogsActive = serviceLogsActive
  }
}
