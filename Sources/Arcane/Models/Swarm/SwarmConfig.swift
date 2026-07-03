import Foundation

/// A swarm config (named blob mountable into services).
public struct SwarmConfigSummary: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var version: JSONValue
  public var createdAt: Date
  public var updatedAt: Date
  public var spec: JSONValue

  public init(
    id: String,
    version: JSONValue,
    createdAt: Date,
    updatedAt: Date,
    spec: JSONValue
  ) {
    self.id = id
    self.version = version
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.spec = spec
  }
}

/// Body for creating a swarm config (`spec` is the raw Docker ConfigSpec).
public struct SwarmConfigCreateRequest: Codable, Hashable, Sendable {
  public var spec: JSONValue

  public init(spec: JSONValue) {
    self.spec = spec
  }
}

/// Body for updating a swarm config.
public struct SwarmConfigUpdateRequest: Codable, Hashable, Sendable {
  public var version: UInt64?
  public var spec: JSONValue

  public init(version: UInt64? = nil, spec: JSONValue) {
    self.version = version
    self.spec = spec
  }
}
