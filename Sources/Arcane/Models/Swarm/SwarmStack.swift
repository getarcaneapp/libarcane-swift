import Foundation

/// A swarm stack as listed by the stacks endpoint.
public struct SwarmStackSummary: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var name: String
  public var namespace: String
  public var services: Int
  public var createdAt: Date
  public var updatedAt: Date

  public init(
    id: String,
    name: String,
    namespace: String,
    services: Int,
    createdAt: Date,
    updatedAt: Date
  ) {
    self.id = id
    self.name = name
    self.namespace = namespace
    self.services = services
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

/// A swarm stack inspect payload (no ID — stacks are keyed by name).
public struct SwarmStackInspect: Codable, Hashable, Sendable {
  public var name: String
  public var namespace: String
  public var services: Int
  public var createdAt: Date
  public var updatedAt: Date

  public init(
    name: String,
    namespace: String,
    services: Int,
    createdAt: Date,
    updatedAt: Date
  ) {
    self.name = name
    self.namespace = namespace
    self.services = services
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

/// A file synced alongside a swarm stack compose deployment.
public struct SwarmSyncFile: Codable, Hashable, Sendable {
  public var relativePath: String
  public var content: Data

  public init(relativePath: String, content: Data) {
    self.relativePath = relativePath
    self.content = content
  }
}

/// Body for `POST /environments/{id}/swarm/stacks` to deploy a stack.
public struct SwarmStackDeployRequest: Codable, Hashable, Sendable {
  public var name: String
  public var composeContent: String
  public var envContent: String?
  public var files: [SwarmSyncFile]?
  public var withRegistryAuth: Bool?
  public var prune: Bool?
  public var resolveImage: String?
  public var workingDir: String?

  public init(
    name: String,
    composeContent: String,
    envContent: String? = nil,
    files: [SwarmSyncFile]? = nil,
    withRegistryAuth: Bool? = nil,
    prune: Bool? = nil,
    resolveImage: String? = nil,
    workingDir: String? = nil
  ) {
    self.name = name
    self.composeContent = composeContent
    self.envContent = envContent
    self.files = files
    self.withRegistryAuth = withRegistryAuth
    self.prune = prune
    self.resolveImage = resolveImage
    self.workingDir = workingDir
  }
}

/// Result of `POST /environments/{id}/swarm/stacks`.
public struct SwarmStackDeployResponse: Codable, Hashable, Sendable {
  public var name: String

  public init(name: String) {
    self.name = name
  }
}

/// Persisted source for a deployed stack.
public struct SwarmStackSource: Codable, Hashable, Sendable {
  public var name: String
  public var composeContent: String
  public var envContent: String?
  public var files: [SwarmSyncFile]?

  public init(
    name: String,
    composeContent: String,
    envContent: String? = nil,
    files: [SwarmSyncFile]? = nil
  ) {
    self.name = name
    self.composeContent = composeContent
    self.envContent = envContent
    self.files = files
  }
}

/// Update payload for the persisted stack source.
public struct SwarmStackSourceUpdateRequest: Codable, Hashable, Sendable {
  public var composeContent: String
  public var envContent: String?
  public var files: [SwarmSyncFile]?

  public init(
    composeContent: String,
    envContent: String? = nil,
    files: [SwarmSyncFile]? = nil
  ) {
    self.composeContent = composeContent
    self.envContent = envContent
    self.files = files
  }
}

/// Render/validate request for a compose file before deploying.
public struct SwarmStackRenderConfigRequest: Codable, Hashable, Sendable {
  public var name: String
  public var composeContent: String
  public var envContent: String?

  public init(name: String, composeContent: String, envContent: String? = nil) {
    self.name = name
    self.composeContent = composeContent
    self.envContent = envContent
  }
}

/// Result of rendering a compose config — normalized YAML plus referenced resources.
public struct SwarmStackRenderConfigResponse: Codable, Hashable, Sendable {
  public var name: String
  public var renderedCompose: String
  public var services: [String]
  public var networks: [String]
  public var volumes: [String]
  public var configs: [String]
  public var secrets: [String]
  public var warnings: [String]?

  public init(
    name: String,
    renderedCompose: String,
    services: [String] = [],
    networks: [String] = [],
    volumes: [String] = [],
    configs: [String] = [],
    secrets: [String] = [],
    warnings: [String]? = nil
  ) {
    self.name = name
    self.renderedCompose = renderedCompose
    self.services = services
    self.networks = networks
    self.volumes = volumes
    self.configs = configs
    self.secrets = secrets
    self.warnings = warnings
  }
}
