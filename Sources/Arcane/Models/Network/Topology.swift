import Foundation

/// TopologyNodeType distinguishes network nodes from container nodes.
public enum TopologyNodeType: String, Codable, Hashable, Sendable {
  case network
  case container
}

/// TopologyNodeMetadata carries additional context shown by the UI.
public struct TopologyNodeMetadata: Codable, Hashable, Sendable {
  public var driver: String?
  public var scope: String?
  public var status: String?
  public var image: String?
  public var isDefault: Bool?

  public init(
    driver: String? = nil,
    scope: String? = nil,
    status: String? = nil,
    image: String? = nil,
    isDefault: Bool? = nil
  ) {
    self.driver = driver
    self.scope = scope
    self.status = status
    self.image = image
    self.isDefault = isDefault
  }
}

/// TopologyNode is a single node (network or container) in the topology graph.
public struct TopologyNode: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var name: String
  public var type: TopologyNodeType
  public var metadata: TopologyNodeMetadata

  public init(
    id: String,
    name: String,
    type: TopologyNodeType,
    metadata: TopologyNodeMetadata = TopologyNodeMetadata()
  ) {
    self.id = id
    self.name = name
    self.type = type
    self.metadata = metadata
  }
}

/// TopologyEdge is a directed edge from a network node to a container node.
public struct TopologyEdge: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var source: String
  public var target: String
  public var ipv4Address: String?
  public var ipv6Address: String?

  public init(
    id: String,
    source: String,
    target: String,
    ipv4Address: String? = nil,
    ipv6Address: String? = nil
  ) {
    self.id = id
    self.source = source
    self.target = target
    self.ipv4Address = ipv4Address
    self.ipv6Address = ipv6Address
  }
}

/// NetworkTopology is the full topology graph for a Docker environment.
public struct NetworkTopology: Codable, Hashable, Sendable {
  public var nodes: [TopologyNode]
  public var edges: [TopologyEdge]

  public init(nodes: [TopologyNode] = [], edges: [TopologyEdge] = []) {
    self.nodes = nodes
    self.edges = edges
  }
}
