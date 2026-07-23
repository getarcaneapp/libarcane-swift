import Foundation

/// State of the Arcane node-agent reporting back from a swarm node.
public enum SwarmNodeAgentState: Hashable, Sendable, RawRepresentable, Codable {
  case none
  case pending
  case offline
  case connected
  case mismatched
  case ambiguous
  case unknown(String)

  public init?(rawValue: String) {
    switch rawValue {
    case "none": self = .none
    case "pending": self = .pending
    case "offline": self = .offline
    case "connected": self = .connected
    case "mismatched": self = .mismatched
    case "ambiguous": self = .ambiguous
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .none: "none"
    case .pending: "pending"
    case .offline: "offline"
    case .connected: "connected"
    case .mismatched: "mismatched"
    case .ambiguous: "ambiguous"
    case .unknown(let value): value
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self = SwarmNodeAgentState(rawValue: try container.decode(String.self)) ?? .none
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

public enum SwarmNodeAgentBindingKind: Hashable, Sendable, RawRepresentable, Codable {
  case local
  case environment
  case dedicated
  case unknown(String)

  public init?(rawValue: String) {
    switch rawValue {
    case "local": self = .local
    case "environment": self = .environment
    case "dedicated": self = .dedicated
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .local: "local"
    case .environment: "environment"
    case .dedicated: "dedicated"
    case .unknown(let value): value
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self = SwarmNodeAgentBindingKind(rawValue: try container.decode(String.self)) ?? .unknown("")
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

public struct SwarmNodeAgentCandidate: Codable, Hashable, Sendable, Identifiable {
  public var environmentID: String
  public var environmentName: String
  public var environmentType: String

  public var id: String { environmentID }

  public enum CodingKeys: String, CodingKey {
    case environmentID = "environmentId"
    case environmentName, environmentType
  }

  public init(environmentID: String, environmentName: String, environmentType: String) {
    self.environmentID = environmentID
    self.environmentName = environmentName
    self.environmentType = environmentType
  }
}

/// Coverage info for a swarm node from Arcane's node-agent perspective.
public struct SwarmNodeAgentStatus: Codable, Hashable, Sendable {
  public var state: SwarmNodeAgentState
  public var bindingKind: SwarmNodeAgentBindingKind?
  public var environmentId: String?
  public var environmentName: String?
  public var environmentType: String?
  public var connected: Bool?
  public var lastHeartbeat: Date?
  public var lastPollAt: Date?
  public var reportedNodeId: String?
  public var reportedHostname: String?
  public var candidates: [SwarmNodeAgentCandidate]

  public enum CodingKeys: String, CodingKey {
    case state, bindingKind, environmentId, environmentName, environmentType
    case connected, lastHeartbeat, lastPollAt, reportedNodeId, reportedHostname, candidates
  }

  public init(
    state: SwarmNodeAgentState,
    bindingKind: SwarmNodeAgentBindingKind? = nil,
    environmentId: String? = nil,
    environmentName: String? = nil,
    environmentType: String? = nil,
    connected: Bool? = nil,
    lastHeartbeat: Date? = nil,
    lastPollAt: Date? = nil,
    reportedNodeId: String? = nil,
    reportedHostname: String? = nil,
    candidates: [SwarmNodeAgentCandidate] = []
  ) {
    self.state = state
    self.bindingKind = bindingKind
    self.environmentId = environmentId
    self.environmentName = environmentName
    self.environmentType = environmentType
    self.connected = connected
    self.lastHeartbeat = lastHeartbeat
    self.lastPollAt = lastPollAt
    self.reportedNodeId = reportedNodeId
    self.reportedHostname = reportedHostname
    self.candidates = candidates
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    state = try container.decodeIfPresent(SwarmNodeAgentState.self, forKey: .state) ?? .none
    bindingKind = try container.decodeIfPresent(
      SwarmNodeAgentBindingKind.self, forKey: .bindingKind)
    environmentId = try container.decodeIfPresent(String.self, forKey: .environmentId)
    environmentName = try container.decodeIfPresent(String.self, forKey: .environmentName)
    environmentType = try container.decodeIfPresent(String.self, forKey: .environmentType)
    connected = try container.decodeIfPresent(Bool.self, forKey: .connected)
    lastHeartbeat = try container.decodeIfPresent(Date.self, forKey: .lastHeartbeat)
    lastPollAt = try container.decodeIfPresent(Date.self, forKey: .lastPollAt)
    reportedNodeId = try container.decodeIfPresent(String.self, forKey: .reportedNodeId)
    reportedHostname = try container.decodeIfPresent(String.self, forKey: .reportedHostname)
    candidates =
      try container.decodeIfPresent([SwarmNodeAgentCandidate].self, forKey: .candidates) ?? []
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
  public var managerAddress: String?
  public var reachability: String?
  public var labels: [String: String]?
  public var systemLabels: [String: String]?
  public var engineVersion: String?
  public var platform: String?
  public var createdAt: Date
  public var updatedAt: Date
  public var agent: SwarmNodeAgentStatus

  public enum CodingKeys: String, CodingKey {
    case id, hostname, role, availability, status, address, managerStatus, managerAddress
    case reachability, labels, systemLabels, engineVersion, platform, createdAt, updatedAt, agent
  }

  public init(
    id: String,
    hostname: String,
    role: String,
    availability: String,
    status: String,
    address: String? = nil,
    managerStatus: String? = nil,
    managerAddress: String? = nil,
    reachability: String? = nil,
    labels: [String: String]? = nil,
    systemLabels: [String: String]? = nil,
    engineVersion: String? = nil,
    platform: String? = nil,
    createdAt: Date,
    updatedAt: Date,
    agent: SwarmNodeAgentStatus = .init(state: .none)
  ) {
    self.id = id
    self.hostname = hostname
    self.role = role
    self.availability = availability
    self.status = status
    self.address = address
    self.managerStatus = managerStatus
    self.managerAddress = managerAddress
    self.reachability = reachability
    self.labels = labels
    self.systemLabels = systemLabels
    self.engineVersion = engineVersion
    self.platform = platform
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.agent = agent
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    hostname = try container.decode(String.self, forKey: .hostname)
    role = try container.decode(String.self, forKey: .role)
    availability = try container.decode(String.self, forKey: .availability)
    status = try container.decode(String.self, forKey: .status)
    address = try container.decodeIfPresent(String.self, forKey: .address)
    managerStatus = try container.decodeIfPresent(String.self, forKey: .managerStatus)
    managerAddress = try container.decodeIfPresent(String.self, forKey: .managerAddress)
    reachability = try container.decodeIfPresent(String.self, forKey: .reachability)
    labels = try container.decodeIfPresent([String: String].self, forKey: .labels)
    systemLabels = try container.decodeIfPresent([String: String].self, forKey: .systemLabels)
    engineVersion = try container.decodeIfPresent(String.self, forKey: .engineVersion)
    platform = try container.decodeIfPresent(String.self, forKey: .platform)
    createdAt = try container.decode(Date.self, forKey: .createdAt)
    updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    agent =
      try container.decodeIfPresent(SwarmNodeAgentStatus.self, forKey: .agent)
      ?? SwarmNodeAgentStatus(state: .none)
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
