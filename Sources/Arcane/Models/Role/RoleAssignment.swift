import Foundation

public enum RoleAssignmentSource: String, Codable, Hashable, Sendable {
  case manual
  case oidc
}

public struct RoleAssignment: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var userId: String
  public var roleId: String
  public var environmentId: String?
  public var source: String
  public var createdAt: Date

  public init(
    id: String,
    userId: String,
    roleId: String,
    environmentId: String? = nil,
    source: String = RoleAssignmentSource.manual.rawValue,
    createdAt: Date
  ) {
    self.id = id
    self.userId = userId
    self.roleId = roleId
    self.environmentId = environmentId
    self.source = source
    self.createdAt = createdAt
  }

  public var sourceKind: RoleAssignmentSource? { RoleAssignmentSource(rawValue: source) }
}

public struct RoleAssignmentSummary: Codable, Hashable, Sendable {
  public var roleId: String
  public var environmentId: String?
  public var source: String

  public init(
    roleId: String,
    environmentId: String? = nil,
    source: String = RoleAssignmentSource.manual.rawValue
  ) {
    self.roleId = roleId
    self.environmentId = environmentId
    self.source = source
  }

  public var sourceKind: RoleAssignmentSource? { RoleAssignmentSource(rawValue: source) }
}

public struct UserAssignmentInput: Codable, Hashable, Sendable {
  public var roleId: String
  public var environmentId: String?

  public init(roleId: String, environmentId: String? = nil) {
    self.roleId = roleId
    self.environmentId = environmentId
  }
}

public struct SetUserAssignments: Codable, Hashable, Sendable {
  public var assignments: [UserAssignmentInput]

  public init(assignments: [UserAssignmentInput]) {
    self.assignments = assignments
  }
}
