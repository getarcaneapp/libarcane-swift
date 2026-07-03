import Foundation

/// Runtime status reflecting whether swarm mode is enabled in this environment.
public struct SwarmRuntimeStatus: Codable, Hashable, Sendable {
  public var enabled: Bool

  public init(enabled: Bool) {
    self.enabled = enabled
  }
}

/// Top-level information about the swarm cluster. The full Docker `Spec` blob is
/// preserved as opaque JSON.
public struct SwarmInfo: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var createdAt: Date
  public var updatedAt: Date
  public var spec: JSONValue
  public var rootRotationInProgress: Bool

  public init(
    id: String,
    createdAt: Date,
    updatedAt: Date,
    spec: JSONValue,
    rootRotationInProgress: Bool
  ) {
    self.id = id
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.spec = spec
    self.rootRotationInProgress = rootRotationInProgress
  }
}
