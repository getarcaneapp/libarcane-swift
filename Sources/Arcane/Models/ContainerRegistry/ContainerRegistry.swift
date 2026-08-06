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
  public var repositoryNames: [String]
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
    repositoryNames: [String] = [],
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
    self.repositoryNames = repositoryNames
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  private enum CodingKeys: String, CodingKey {
    case id, url, username, description, insecure, enabled, registryType
    case awsAccessKeyId, awsRegion, repositoryNames, createdAt, updatedAt
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    url = try container.decode(String.self, forKey: .url)
    username = try container.decode(String.self, forKey: .username)
    description = try container.decodeIfPresent(String.self, forKey: .description)
    insecure = try container.decode(Bool.self, forKey: .insecure)
    enabled = try container.decode(Bool.self, forKey: .enabled)
    registryType = try container.decode(String.self, forKey: .registryType)
    awsAccessKeyId = try container.decodeIfPresent(String.self, forKey: .awsAccessKeyId)
    awsRegion = try container.decodeIfPresent(String.self, forKey: .awsRegion)
    repositoryNames = try container.decodeIfPresent([String].self, forKey: .repositoryNames) ?? []
    createdAt = try container.decode(Date.self, forKey: .createdAt)
    updatedAt = try container.decode(Date.self, forKey: .updatedAt)
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
  public var repositoryNames: [String]?

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
    awsRegion: String? = nil,
    repositoryNames: [String]? = nil
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
    self.repositoryNames = repositoryNames
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
  public var repositoryNames: [String]?

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
    awsRegion: String? = nil,
    repositoryNames: [String]? = nil
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
    self.repositoryNames = repositoryNames
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
  public var repositoryNames: [String] {
    didSet { encodesRepositoryNames = true }
  }
  public var createdAt: Date
  public var updatedAt: Date
  private var encodesRepositoryNames: Bool

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
    repositoryNames: [String]? = nil,
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
    self.repositoryNames = repositoryNames ?? []
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.encodesRepositoryNames = repositoryNames != nil
  }

  private enum CodingKeys: String, CodingKey {
    case id, url, username, token, description, insecure, enabled, registryType
    case awsAccessKeyId, awsSecretAccessKey, awsRegion, repositoryNames, createdAt, updatedAt
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    url = try container.decode(String.self, forKey: .url)
    username = try container.decode(String.self, forKey: .username)
    token = try container.decode(String.self, forKey: .token)
    description = try container.decodeIfPresent(String.self, forKey: .description)
    insecure = try container.decode(Bool.self, forKey: .insecure)
    enabled = try container.decode(Bool.self, forKey: .enabled)
    registryType = try container.decode(String.self, forKey: .registryType)
    awsAccessKeyId = try container.decodeIfPresent(String.self, forKey: .awsAccessKeyId)
    awsSecretAccessKey = try container.decodeIfPresent(
      String.self, forKey: .awsSecretAccessKey)
    awsRegion = try container.decodeIfPresent(String.self, forKey: .awsRegion)
    repositoryNames =
      try container.decodeIfPresent([String].self, forKey: .repositoryNames) ?? []
    createdAt = try container.decode(Date.self, forKey: .createdAt)
    updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    encodesRepositoryNames = container.contains(.repositoryNames)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(url, forKey: .url)
    try container.encode(username, forKey: .username)
    try container.encode(token, forKey: .token)
    try container.encodeIfPresent(description, forKey: .description)
    try container.encode(insecure, forKey: .insecure)
    try container.encode(enabled, forKey: .enabled)
    try container.encode(registryType, forKey: .registryType)
    try container.encodeIfPresent(awsAccessKeyId, forKey: .awsAccessKeyId)
    try container.encodeIfPresent(awsSecretAccessKey, forKey: .awsSecretAccessKey)
    try container.encodeIfPresent(awsRegion, forKey: .awsRegion)
    if encodesRepositoryNames {
      try container.encode(repositoryNames, forKey: .repositoryNames)
    }
    try container.encode(createdAt, forKey: .createdAt)
    try container.encode(updatedAt, forKey: .updatedAt)
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
