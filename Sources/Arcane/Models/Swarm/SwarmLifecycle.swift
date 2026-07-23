import Foundation

public struct SwarmNodeAgentReconcileResult: Codable, Hashable, Sendable, Identifiable {
  public var nodeID: String
  public var state: SwarmNodeAgentState
  public var environmentID: String?
  public var candidates: [SwarmNodeAgentCandidate]

  public var id: String { nodeID }

  public enum CodingKeys: String, CodingKey {
    case nodeID = "nodeId"
    case state
    case environmentID = "environmentId"
    case candidates
  }

  public init(
    nodeID: String,
    state: SwarmNodeAgentState,
    environmentID: String? = nil,
    candidates: [SwarmNodeAgentCandidate] = []
  ) {
    self.nodeID = nodeID
    self.state = state
    self.environmentID = environmentID
    self.candidates = candidates
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    nodeID = try container.decode(String.self, forKey: .nodeID)
    state = try container.decodeIfPresent(SwarmNodeAgentState.self, forKey: .state) ?? .none
    environmentID = try container.decodeIfPresent(String.self, forKey: .environmentID)
    candidates =
      try container.decodeIfPresent([SwarmNodeAgentCandidate].self, forKey: .candidates) ?? []
  }
}

public struct SwarmNodeAgentReconcileResponse: Codable, Hashable, Sendable {
  public var results: [SwarmNodeAgentReconcileResult]

  public init(results: [SwarmNodeAgentReconcileResult] = []) {
    self.results = results
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    results =
      try container.decodeIfPresent([SwarmNodeAgentReconcileResult].self, forKey: .results) ?? []
  }
}

public struct SwarmNodeAgentBindingRequest: Codable, Hashable, Sendable {
  public var environmentID: String
  public var rebind: Bool
  public var replaceDeployment: Bool

  public enum CodingKeys: String, CodingKey {
    case environmentID = "environmentId"
    case rebind, replaceDeployment
  }

  public init(
    environmentID: String,
    rebind: Bool = false,
    replaceDeployment: Bool = false
  ) {
    self.environmentID = environmentID
    self.rebind = rebind
    self.replaceDeployment = replaceDeployment
  }
}

public struct SwarmJoinCandidate: Codable, Hashable, Sendable, Identifiable {
  public var environmentID: String
  public var environmentName: String
  public var environmentType: String
  public var status: String

  public var id: String { environmentID }

  public enum CodingKeys: String, CodingKey {
    case environmentID = "environmentId"
    case environmentName, environmentType, status
  }

  public init(
    environmentID: String,
    environmentName: String,
    environmentType: String,
    status: String
  ) {
    self.environmentID = environmentID
    self.environmentName = environmentName
    self.environmentType = environmentType
    self.status = status
  }
}

public enum SwarmJoinEnvironmentRole: Hashable, Sendable, RawRepresentable, Codable {
  case worker
  case manager
  case unknown(String)

  public init?(rawValue: String) {
    switch rawValue {
    case "worker": self = .worker
    case "manager": self = .manager
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .worker: "worker"
    case .manager: "manager"
    case .unknown(let value): value
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self = SwarmJoinEnvironmentRole(rawValue: try container.decode(String.self)) ?? .unknown("")
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

public struct SwarmJoinEnvironmentTarget: Codable, Hashable, Sendable {
  public var environmentID: String
  public var role: SwarmJoinEnvironmentRole
  public var availability: String?
  public var listenAddr: String?
  public var advertiseAddr: String?
  public var dataPathAddr: String?

  public enum CodingKeys: String, CodingKey {
    case environmentID = "environmentId"
    case role, availability, listenAddr, advertiseAddr, dataPathAddr
  }

  public init(
    environmentID: String,
    role: SwarmJoinEnvironmentRole,
    availability: String? = nil,
    listenAddr: String? = nil,
    advertiseAddr: String? = nil,
    dataPathAddr: String? = nil
  ) {
    self.environmentID = environmentID
    self.role = role
    self.availability = availability
    self.listenAddr = listenAddr
    self.advertiseAddr = advertiseAddr
    self.dataPathAddr = dataPathAddr
  }
}

public struct SwarmJoinEnvironmentsRequest: Codable, Hashable, Sendable {
  public var remoteAddrs: [String]
  public var targets: [SwarmJoinEnvironmentTarget]

  public init(
    remoteAddrs: [String] = [],
    targets: [SwarmJoinEnvironmentTarget]
  ) {
    self.remoteAddrs = remoteAddrs
    self.targets = targets
  }
}

public enum SwarmJoinEnvironmentResultState: Hashable, Sendable, RawRepresentable, Codable {
  case joined
  case alreadyMember
  case joinedUnverified
  case failed
  case unknown(String)

  public init?(rawValue: String) {
    switch rawValue {
    case "joined": self = .joined
    case "already_member": self = .alreadyMember
    case "joined_unverified": self = .joinedUnverified
    case "failed": self = .failed
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .joined: "joined"
    case .alreadyMember: "already_member"
    case .joinedUnverified: "joined_unverified"
    case .failed: "failed"
    case .unknown(let value): value
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self =
      SwarmJoinEnvironmentResultState(rawValue: try container.decode(String.self))
      ?? .unknown("")
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

public struct SwarmJoinEnvironmentResult: Codable, Hashable, Sendable, Identifiable {
  public var environmentID: String
  public var state: SwarmJoinEnvironmentResultState
  public var nodeID: String?
  public var error: String?

  public var id: String { environmentID }

  public enum CodingKeys: String, CodingKey {
    case environmentID = "environmentId"
    case state
    case nodeID = "nodeId"
    case error
  }

  public init(
    environmentID: String,
    state: SwarmJoinEnvironmentResultState,
    nodeID: String? = nil,
    error: String? = nil
  ) {
    self.environmentID = environmentID
    self.state = state
    self.nodeID = nodeID
    self.error = error
  }
}

public struct SwarmJoinEnvironmentsResponse: Codable, Hashable, Sendable {
  public var results: [SwarmJoinEnvironmentResult]

  public init(results: [SwarmJoinEnvironmentResult] = []) {
    self.results = results
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    results =
      try container.decodeIfPresent([SwarmJoinEnvironmentResult].self, forKey: .results) ?? []
  }
}
