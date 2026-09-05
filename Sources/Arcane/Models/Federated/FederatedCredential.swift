import Foundation

public struct FederatedCredential: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var name: String
  public var description: String?
  public var enabled: Bool
  public var issuerUrl: String
  public var audiences: [String]
  public var subjectClaim: String
  public var subjectMatch: String
  public var matchType: String
  public var roleId: String
  public var environmentId: String?
  public var tokenTtlSeconds: Int
  public var expiresAt: Date?
  public var identityUserId: String
  public var lastUsedAt: Date?
  public var createdAt: Date
  public var updatedAt: Date?
  public var serviceUsername: String?
  public var roleName: String?
  public var environmentName: String?

  public init(
    id: String,
    name: String,
    description: String? = nil,
    enabled: Bool,
    issuerUrl: String,
    audiences: [String],
    subjectClaim: String,
    subjectMatch: String,
    matchType: String,
    roleId: String,
    environmentId: String? = nil,
    tokenTtlSeconds: Int,
    expiresAt: Date? = nil,
    identityUserId: String,
    lastUsedAt: Date? = nil,
    createdAt: Date,
    updatedAt: Date? = nil,
    serviceUsername: String? = nil,
    roleName: String? = nil,
    environmentName: String? = nil
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.enabled = enabled
    self.issuerUrl = issuerUrl
    self.audiences = audiences
    self.subjectClaim = subjectClaim
    self.subjectMatch = subjectMatch
    self.matchType = matchType
    self.roleId = roleId
    self.environmentId = environmentId
    self.tokenTtlSeconds = tokenTtlSeconds
    self.expiresAt = expiresAt
    self.identityUserId = identityUserId
    self.lastUsedAt = lastUsedAt
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.serviceUsername = serviceUsername
    self.roleName = roleName
    self.environmentName = environmentName
  }
}

public struct CreateFederatedCredential: Codable, Hashable, Sendable {
  public var name: String
  public var description: String?
  public var enabled: Bool
  public var issuerUrl: String
  public var audiences: [String]
  public var subjectClaim: String
  public var subjectMatch: String
  public var matchType: String
  public var roleId: String
  public var environmentId: String?
  public var tokenTtlSeconds: Int
  public var expiresAt: Date?

  public init(
    name: String,
    description: String? = nil,
    enabled: Bool,
    issuerUrl: String,
    audiences: [String],
    subjectClaim: String,
    subjectMatch: String,
    matchType: String,
    roleId: String,
    environmentId: String? = nil,
    tokenTtlSeconds: Int,
    expiresAt: Date? = nil
  ) {
    self.name = name
    self.description = description
    self.enabled = enabled
    self.issuerUrl = issuerUrl
    self.audiences = audiences
    self.subjectClaim = subjectClaim
    self.subjectMatch = subjectMatch
    self.matchType = matchType
    self.roleId = roleId
    self.environmentId = environmentId
    self.tokenTtlSeconds = tokenTtlSeconds
    self.expiresAt = expiresAt
  }
}

public struct UpdateFederatedCredential: Codable, Hashable, Sendable {
  public var name: String?
  public var description: String?
  public var enabled: Bool?
  public var issuerUrl: String?
  public var audiences: [String]?
  public var subjectClaim: String?
  public var subjectMatch: String?
  public var matchType: String?
  public var roleId: String?
  public var environmentId: String?
  public var tokenTtlSeconds: Int?
  public var expiresAt: Date?

  public init(
    name: String? = nil,
    description: String? = nil,
    enabled: Bool? = nil,
    issuerUrl: String? = nil,
    audiences: [String]? = nil,
    subjectClaim: String? = nil,
    subjectMatch: String? = nil,
    matchType: String? = nil,
    roleId: String? = nil,
    environmentId: String? = nil,
    tokenTtlSeconds: Int? = nil,
    expiresAt: Date? = nil
  ) {
    self.name = name
    self.description = description
    self.enabled = enabled
    self.issuerUrl = issuerUrl
    self.audiences = audiences
    self.subjectClaim = subjectClaim
    self.subjectMatch = subjectMatch
    self.matchType = matchType
    self.roleId = roleId
    self.environmentId = environmentId
    self.tokenTtlSeconds = tokenTtlSeconds
    self.expiresAt = expiresAt
  }
}
