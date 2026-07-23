import Foundation

/// Source of templates returned by the merged template list.
public enum TemplateSourceFilter: String, Codable, Hashable, Sendable {
  case all
  case local
  case remote

  var queryValue: String? {
    switch self {
    case .all: nil
    case .local: "false"
    case .remote: "true"
    }
  }
}

public struct Template: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var name: String
  public var description: String
  public var content: String
  public var envContent: String?
  public var isCustom: Bool
  public var isRemote: Bool
  public var registryId: String?
  public var registry: TemplateRegistry?
  public var metadata: TemplateMetadata?

  public init(
    id: String,
    name: String,
    description: String,
    content: String,
    envContent: String? = nil,
    isCustom: Bool,
    isRemote: Bool,
    registryId: String? = nil,
    registry: TemplateRegistry? = nil,
    metadata: TemplateMetadata? = nil
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.content = content
    self.envContent = envContent
    self.isCustom = isCustom
    self.isRemote = isRemote
    self.registryId = registryId
    self.registry = registry
    self.metadata = metadata
  }
}

public struct RemoteTemplate: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var name: String
  public var description: String
  public var version: String
  public var author: String
  public var composeUrl: String
  public var envUrl: String
  public var documentationUrl: String
  public var tags: [String]

  public enum CodingKeys: String, CodingKey {
    case id
    case name
    case description
    case version
    case author
    case composeUrl = "compose_url"
    case envUrl = "env_url"
    case documentationUrl = "documentation_url"
    case tags
  }

  public init(
    id: String,
    name: String,
    description: String,
    version: String,
    author: String,
    composeUrl: String,
    envUrl: String,
    documentationUrl: String,
    tags: [String]
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.version = version
    self.author = author
    self.composeUrl = composeUrl
    self.envUrl = envUrl
    self.documentationUrl = documentationUrl
    self.tags = tags
  }
}

public struct TemplateRegistry: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var name: String
  public var description: String
  public var url: String
  public var enabled: Bool
  public var lastFetchError: String?

  public init(
    id: String,
    name: String,
    description: String,
    url: String,
    enabled: Bool,
    lastFetchError: String? = nil
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.url = url
    self.enabled = enabled
    self.lastFetchError = lastFetchError
  }
}

public struct RemoteTemplateRegistry: Codable, Hashable, Sendable {
  public var schema: String?
  public var name: String
  public var description: String
  public var url: String
  public var version: String
  public var author: String
  public var templates: [RemoteTemplate]

  public enum CodingKeys: String, CodingKey {
    case schema = "$schema"
    case name
    case description
    case url
    case version
    case author
    case templates
  }

  public init(
    schema: String? = nil,
    name: String,
    description: String,
    url: String,
    version: String,
    author: String,
    templates: [RemoteTemplate]
  ) {
    self.schema = schema
    self.name = name
    self.description = description
    self.url = url
    self.version = version
    self.author = author
    self.templates = templates
  }
}

public struct TemplateContent: Codable, Hashable, Sendable {
  public var template: Template
  public var content: String
  public var envContent: String
  public var services: [String]
  public var envVariables: [EnvVariable]

  public init(
    template: Template,
    content: String,
    envContent: String,
    services: [String],
    envVariables: [EnvVariable]
  ) {
    self.template = template
    self.content = content
    self.envContent = envContent
    self.services = services
    self.envVariables = envVariables
  }
}

public struct CreateTemplate: Codable, Hashable, Sendable {
  public var name: String
  public var description: String
  public var content: String
  public var envContent: String

  public init(
    name: String,
    description: String = "",
    content: String,
    envContent: String = ""
  ) {
    self.name = name
    self.description = description
    self.content = content
    self.envContent = envContent
  }
}

public struct UpdateTemplate: Codable, Hashable, Sendable {
  public var name: String
  public var description: String
  public var content: String
  public var envContent: String

  public init(
    name: String,
    description: String = "",
    content: String,
    envContent: String = ""
  ) {
    self.name = name
    self.description = description
    self.content = content
    self.envContent = envContent
  }
}

public struct DefaultTemplates: Codable, Hashable, Sendable {
  public var composeTemplate: String
  public var swarmStackTemplate: String
  public var swarmStackEnvTemplate: String
  public var envTemplate: String

  public init(
    composeTemplate: String,
    swarmStackTemplate: String,
    swarmStackEnvTemplate: String,
    envTemplate: String
  ) {
    self.composeTemplate = composeTemplate
    self.swarmStackTemplate = swarmStackTemplate
    self.swarmStackEnvTemplate = swarmStackEnvTemplate
    self.envTemplate = envTemplate
  }
}

public struct SaveDefaultTemplates: Codable, Hashable, Sendable {
  public var composeContent: String
  public var envContent: String

  public init(composeContent: String, envContent: String = "") {
    self.composeContent = composeContent
    self.envContent = envContent
  }
}

public struct CreateTemplateRegistry: Codable, Hashable, Sendable {
  public var name: String
  public var url: String
  public var description: String
  public var enabled: Bool

  public init(name: String, url: String, description: String = "", enabled: Bool = true) {
    self.name = name
    self.url = url
    self.description = description
    self.enabled = enabled
  }
}

public struct UpdateTemplateRegistry: Codable, Hashable, Sendable {
  public var name: String
  public var url: String
  public var description: String
  public var enabled: Bool

  public init(name: String, url: String, description: String = "", enabled: Bool = true) {
    self.name = name
    self.url = url
    self.description = description
    self.enabled = enabled
  }
}
