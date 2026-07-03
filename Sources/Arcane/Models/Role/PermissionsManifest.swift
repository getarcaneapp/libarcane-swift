import Foundation

public enum PermissionResourceScope: String, Codable, Hashable, Sendable {
  case global
  case env
}

public struct PermissionsManifest: Codable, Hashable, Sendable {
  public var resources: [PermissionResource]

  public init(resources: [PermissionResource]) {
    self.resources = resources
  }
}

public struct PermissionResource: Codable, Hashable, Sendable, Identifiable {
  public var key: String
  public var label: String
  public var scope: String
  public var actions: [PermissionAction]

  public init(key: String, label: String, scope: String, actions: [PermissionAction]) {
    self.key = key
    self.label = label
    self.scope = scope
    self.actions = actions
  }

  public var id: String { key }
  public var scopeKind: PermissionResourceScope? { PermissionResourceScope(rawValue: scope) }
}

public struct PermissionAction: Codable, Hashable, Sendable, Identifiable {
  public var key: String
  public var permission: String
  public var label: String
  public var description: String?

  public init(key: String, permission: String, label: String, description: String? = nil) {
    self.key = key
    self.permission = permission
    self.label = label
    self.description = description
  }

  public var id: String { permission }
}
