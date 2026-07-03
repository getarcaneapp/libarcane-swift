import Foundation

/// Metadata describing a configuration / setting field.
public struct ConfigMetadata: Codable, Hashable, Sendable {
  public var key: String
  public var label: String
  public var type: String
  public var keywords: [String]?
  public var description: String?

  public init(
    key: String,
    label: String,
    type: String,
    keywords: [String]? = nil,
    description: String? = nil
  ) {
    self.key = key
    self.label = label
    self.type = type
    self.keywords = keywords
    self.description = description
  }
}

/// Metadata associated with a template (URLs, tags, author etc.).
public struct TemplateMetadata: Codable, Hashable, Sendable {
  public var version: String?
  public var author: String?
  public var tags: [String]?
  public var remoteUrl: String?
  public var envUrl: String?
  public var documentationUrl: String?
  public var iconUrl: String?
  public var updatedAt: String?

  public init(
    version: String? = nil,
    author: String? = nil,
    tags: [String]? = nil,
    remoteUrl: String? = nil,
    envUrl: String? = nil,
    documentationUrl: String? = nil,
    iconUrl: String? = nil,
    updatedAt: String? = nil
  ) {
    self.version = version
    self.author = author
    self.tags = tags
    self.remoteUrl = remoteUrl
    self.envUrl = envUrl
    self.documentationUrl = documentationUrl
    self.iconUrl = iconUrl
    self.updatedAt = updatedAt
  }
}
