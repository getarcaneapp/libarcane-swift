import Foundation

public struct ContainerRegistry: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var url: String
  public var username: String
  public var description: String?
  public var insecure: Bool
  public var enabled: Bool
  public var registryType: String
  public var awsAccessKeyId: String?
  public var awsRegion: String?
  public var createdAt: Date
  public var updatedAt: Date

  public init(
    id: String,
    url: String,
    username: String,
    description: String? = nil,
    insecure: Bool,
    enabled: Bool,
    registryType: String,
    awsAccessKeyId: String? = nil,
    awsRegion: String? = nil,
    createdAt: Date,
    updatedAt: Date
  ) {
    self.id = id
    self.url = url
    self.username = username
    self.description = description
    self.insecure = insecure
    self.enabled = enabled
    self.registryType = registryType
    self.awsAccessKeyId = awsAccessKeyId
    self.awsRegion = awsRegion
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

public struct CreateContainerRegistry: Codable, Hashable, Sendable {
  public var url: String
  public var username: String?
  public var token: String?
  public var description: String?
  public var insecure: Bool?
  public var enabled: Bool?
  public var registryType: String?
  public var awsAccessKeyId: String?
  public var awsSecretAccessKey: String?
  public var awsRegion: String?

  public init(
    url: String,
    username: String? = nil,
    token: String? = nil,
    description: String? = nil,
    insecure: Bool? = nil,
    enabled: Bool? = nil,
    registryType: String? = nil,
    awsAccessKeyId: String? = nil,
    awsSecretAccessKey: String? = nil,
    awsRegion: String? = nil
  ) {
    self.url = url
    self.username = username
    self.token = token
    self.description = description
    self.insecure = insecure
    self.enabled = enabled
    self.registryType = registryType
    self.awsAccessKeyId = awsAccessKeyId
    self.awsSecretAccessKey = awsSecretAccessKey
    self.awsRegion = awsRegion
  }
}

public struct UpdateContainerRegistry: Codable, Hashable, Sendable {
  public var url: String?
  public var username: String?
  public var token: String?
  public var description: String?
  public var insecure: Bool?
  public var enabled: Bool?
  public var registryType: String?
  public var awsAccessKeyId: String?
  public var awsSecretAccessKey: String?
  public var awsRegion: String?

  public init(
    url: String? = nil,
    username: String? = nil,
    token: String? = nil,
    description: String? = nil,
    insecure: Bool? = nil,
    enabled: Bool? = nil,
    registryType: String? = nil,
    awsAccessKeyId: String? = nil,
    awsSecretAccessKey: String? = nil,
    awsRegion: String? = nil
  ) {
    self.url = url
    self.username = username
    self.token = token
    self.description = description
    self.insecure = insecure
    self.enabled = enabled
    self.registryType = registryType
    self.awsAccessKeyId = awsAccessKeyId
    self.awsSecretAccessKey = awsSecretAccessKey
    self.awsRegion = awsRegion
  }
}

public struct ContainerRegistryPullUsageResponse: Codable, Hashable, Sendable {
  public var registries: [ContainerRegistryPullUsage]

  public init(registries: [ContainerRegistryPullUsage]) {
    self.registries = registries
  }
}

public struct ContainerRegistryPullUsage: Codable, Hashable, Sendable {
  public var registryId: String
  public var provider: String
  public var registry: String
  public var displayName: String
  public var repository: String?
  public var limit: Int?
  public var remaining: Int?
  public var used: Int?
  public var windowSeconds: Int?
  public var observedPulls: Int64
  public var authMethod: String
  public var authUsername: String?
  public var source: String?
  public var checkedAt: Date
  public var error: String?

  public init(
    registryId: String,
    provider: String,
    registry: String,
    displayName: String,
    repository: String? = nil,
    limit: Int? = nil,
    remaining: Int? = nil,
    used: Int? = nil,
    windowSeconds: Int? = nil,
    observedPulls: Int64,
    authMethod: String,
    authUsername: String? = nil,
    source: String? = nil,
    checkedAt: Date,
    error: String? = nil
  ) {
    self.registryId = registryId
    self.provider = provider
    self.registry = registry
    self.displayName = displayName
    self.repository = repository
    self.limit = limit
    self.remaining = remaining
    self.used = used
    self.windowSeconds = windowSeconds
    self.observedPulls = observedPulls
    self.authMethod = authMethod
    self.authUsername = authUsername
    self.source = source
    self.checkedAt = checkedAt
    self.error = error
  }
}

public struct ContainerRegistrySync: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var url: String
  public var username: String
  public var token: String
  public var description: String?
  public var insecure: Bool
  public var enabled: Bool
  public var registryType: String
  public var awsAccessKeyId: String?
  public var awsSecretAccessKey: String?
  public var awsRegion: String?
  public var createdAt: Date
  public var updatedAt: Date

  public init(
    id: String,
    url: String,
    username: String,
    token: String,
    description: String? = nil,
    insecure: Bool,
    enabled: Bool,
    registryType: String,
    awsAccessKeyId: String? = nil,
    awsSecretAccessKey: String? = nil,
    awsRegion: String? = nil,
    createdAt: Date,
    updatedAt: Date
  ) {
    self.id = id
    self.url = url
    self.username = username
    self.token = token
    self.description = description
    self.insecure = insecure
    self.enabled = enabled
    self.registryType = registryType
    self.awsAccessKeyId = awsAccessKeyId
    self.awsSecretAccessKey = awsSecretAccessKey
    self.awsRegion = awsRegion
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

public struct ContainerRegistrySyncRequest: Codable, Hashable, Sendable {
  public var registries: [ContainerRegistrySync]

  public init(registries: [ContainerRegistrySync]) {
    self.registries = registries
  }
}

public struct ContainerRegistryCredential: Codable, Hashable, Sendable {
  public var url: String
  public var username: String
  public var token: String
  public var enabled: Bool

  public init(url: String, username: String, token: String, enabled: Bool) {
    self.url = url
    self.username = username
    self.token = token
    self.enabled = enabled
  }
}
