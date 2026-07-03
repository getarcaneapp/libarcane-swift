import Foundation

/// Category metadata used by the settings UI.
public struct SettingCategory: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var title: String
  public var description: String
  public var icon: String
  public var url: String
  public var keywords: [String]
  public var settings: [SettingMetadata]
  public var matchingSettings: [SettingMetadata]?
  public var relevanceScore: Int?

  public init(
    id: String,
    title: String,
    description: String,
    icon: String,
    url: String,
    keywords: [String] = [],
    settings: [SettingMetadata] = [],
    matchingSettings: [SettingMetadata]? = nil,
    relevanceScore: Int? = nil
  ) {
    self.id = id
    self.title = title
    self.description = description
    self.icon = icon
    self.url = url
    self.keywords = keywords
    self.settings = settings
    self.matchingSettings = matchingSettings
    self.relevanceScore = relevanceScore
  }
}

/// Setting-level metadata used by the settings UI.
public struct SettingMetadata: Codable, Hashable, Sendable {
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
