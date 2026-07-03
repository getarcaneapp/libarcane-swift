import Foundation

public struct APIKey: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var name: String
  public var description: String?
  public var keyPrefix: String
  public var userId: String?
  public var isStatic: Bool
  public var expiresAt: Date?
  public var lastUsedAt: Date?
  public var createdAt: Date
  public var updatedAt: Date?

  public init(
    id: String,
    name: String,
    description: String? = nil,
    keyPrefix: String,
    userId: String? = nil,
    isStatic: Bool = false,
    expiresAt: Date? = nil,
    lastUsedAt: Date? = nil,
    createdAt: Date,
    updatedAt: Date? = nil
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.keyPrefix = keyPrefix
    self.userId = userId
    self.isStatic = isStatic
    self.expiresAt = expiresAt
    self.lastUsedAt = lastUsedAt
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

public struct APIKeyCreated: Codable, Hashable, Sendable {
  public var id: String
  public var name: String
  public var description: String?
  public var keyPrefix: String
  public var userId: String?
  public var isStatic: Bool
  public var expiresAt: Date?
  public var lastUsedAt: Date?
  public var createdAt: Date
  public var updatedAt: Date?
  public var key: String

  public init(
    id: String,
    name: String,
    description: String? = nil,
    keyPrefix: String,
    userId: String? = nil,
    isStatic: Bool = false,
    expiresAt: Date? = nil,
    lastUsedAt: Date? = nil,
    createdAt: Date,
    updatedAt: Date? = nil,
    key: String
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.keyPrefix = keyPrefix
    self.userId = userId
    self.isStatic = isStatic
    self.expiresAt = expiresAt
    self.lastUsedAt = lastUsedAt
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.key = key
  }
}

public struct CreateAPIKey: Codable, Hashable, Sendable {
  public var name: String
  public var description: String?
  public var expiresAt: Date?

  public init(name: String, description: String? = nil, expiresAt: Date? = nil) {
    self.name = name
    self.description = description
    self.expiresAt = expiresAt
  }
}

public struct UpdateAPIKey: Codable, Hashable, Sendable {
  public var name: String?
  public var description: String?
  public var expiresAt: Date?

  public init(name: String? = nil, description: String? = nil, expiresAt: Date? = nil) {
    self.name = name
    self.description = description
    self.expiresAt = expiresAt
  }
}
