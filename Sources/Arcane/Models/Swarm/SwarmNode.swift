import Foundation

/// State of the Arcane node-agent reporting back from a swarm node.
public enum SwarmNodeAgentState: String, Codable, Hashable, Sendable {
  case none
  case pending
  case offline
  case connected
  case mismatched
}

/// Coverage info for a swarm node from Arcane's node-agent perspective.
public struct SwarmNodeAgentStatus: Codable, Hashable, Sendable {
  public var state: SwarmNodeAgentState
  public var environmentId: String?
  public var connected: Bool?
  public var lastHeartbeat: Date?
  public var lastPollAt: Date?
  public var reportedNodeId: String?
  public var reportedHostname: String?

  public init(
    state: SwarmNodeAgentState,
    environmentId: String? = nil,
    connected: Bool? = nil,
    lastHeartbeat: Date? = nil,
    lastPollAt: Date? = nil,
    reportedNodeId: String? = nil,
    reportedHostname: String? = nil
  ) {
    self.state = state
    self.environmentId = environmentId
    self.connected = connected
    self.lastHeartbeat = lastHeartbeat
    self.lastPollAt = lastPollAt
    self.reportedNodeId = reportedNodeId
    self.reportedHostname = reportedHostname
  }
}

/// A swarm node summary as returned by the list/get endpoints.
public struct SwarmNode: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var hostname: String
  public var role: String
  public var availability: String
  public var status: String
  public var address: String?
  public var managerStatus: String?
  public var reachability: String?
  public var labels: [String: String]?
  public var systemLabels: [String: String]?
  public var engineVersion: String?
  public var platform: String?
  public var createdAt: Date
  public var updatedAt: Date
  public var agent: SwarmNodeAgentStatus

  public init(
    id: String,
    hostname: String,
    role: String,
    availability: String,
    status: String,
    address: String? = nil,
    managerStatus: String? = nil,
    reachability: String? = nil,
    labels: [String: String]? = nil,
    systemLabels: [String: String]? = nil,
    engineVersion: String? = nil,
    platform: String? = nil,
    createdAt: Date,
    updatedAt: Date,
    agent: SwarmNodeAgentStatus
  ) {
    self.id = id
    self.hostname = hostname
    self.role = role
    self.availability = availability
    self.status = status
    self.address = address
    self.managerStatus = managerStatus
    self.reachability = reachability
    self.labels = labels
    self.systemLabels = systemLabels
    self.engineVersion = engineVersion
    self.platform = platform
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.agent = agent
  }
}

/// Request payload for updating a swarm node's spec.
public struct SwarmNodeUpdateRequest: Codable, Hashable, Sendable {
  public var version: UInt64?
  public var name: String?
  public var labels: [String: String]?
  public var role: String?
  public var availability: String?

  public init(
    version: UInt64? = nil,
    name: String? = nil,
    labels: [String: String]? = nil,
    role: String? = nil,
    availability: String? = nil
  ) {
    self.version = version
    self.name = name
    self.labels = labels
    self.role = role
    self.availability = availability
  }
}

/// Request for the swarm node agent deployment-snippet endpoint.
public struct SwarmNodeAgentDeploymentRequest: Codable, Hashable, Sendable {
  public var rotate: Bool

  public init(rotate: Bool = false) {
    self.rotate = rotate
  }
}

/// File payload returned alongside deployment snippets (re-stated here so the
/// swarm module is self-contained even before the environments module is
/// ported).
public struct SwarmDeploymentSnippetFile: Codable, Hashable, Sendable {
  public var name: String
  public var content: String?
  public var downloadUrl: String?
  public var sensitive: Bool?
  public var containerPath: String
  public var permissions: String

  public init(
    name: String,
    content: String? = nil,
    downloadUrl: String? = nil,
    sensitive: Bool? = nil,
    containerPath: String,
    permissions: String
  ) {
    self.name = name
    self.content = content
    self.downloadUrl = downloadUrl
    self.sensitive = sensitive
    self.containerPath = containerPath
    self.permissions = permissions
  }
}

public struct SwarmDeploymentSnippetMTLS: Codable, Hashable, Sendable {
  public var dockerRun: String
  public var dockerCompose: String
  public var files: [SwarmDeploymentSnippetFile]
  public var hostDirHint: String

  public init(
    dockerRun: String,
    dockerCompose: String,
    files: [SwarmDeploymentSnippetFile] = [],
    hostDirHint: String
  ) {
    self.dockerRun = dockerRun
    self.dockerCompose = dockerCompose
    self.files = files
    self.hostDirHint = hostDirHint
  }
}

/// Bundle of docker-run / docker-compose deployment snippets for a swarm node.
public struct SwarmNodeAgentDeployment: Codable, Hashable, Sendable {
  public var dockerRun: String
  public var dockerCompose: String
  public var mtls: SwarmDeploymentSnippetMTLS?
  public var environmentId: String
  public var agent: SwarmNodeAgentStatus

  public init(
    dockerRun: String,
    dockerCompose: String,
    mtls: SwarmDeploymentSnippetMTLS? = nil,
    environmentId: String,
    agent: SwarmNodeAgentStatus
  ) {
    self.dockerRun = dockerRun
    self.dockerCompose = dockerCompose
    self.mtls = mtls
    self.environmentId = environmentId
    self.agent = agent
  }
}

/// Identifies the local swarm node (used by the cross-environment node identity endpoint).
public struct SwarmNodeIdentity: Codable, Hashable, Sendable {
  public var swarmNodeId: String
  public var hostname: String
  public var role: String
  public var engineVersion: String
  public var swarmActive: Bool

  public init(
    swarmNodeId: String,
    hostname: String,
    role: String,
    engineVersion: String,
    swarmActive: Bool
  ) {
    self.swarmNodeId = swarmNodeId
    self.hostname = hostname
    self.role = role
    self.engineVersion = engineVersion
    self.swarmActive = swarmActive
  }
}
