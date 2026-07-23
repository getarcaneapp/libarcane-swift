import Foundation

public enum PermissionResourceScope: String, Codable, Hashable, Sendable {
  case global
  case env
}

public struct PermissionsManifest: Codable, Hashable, Sendable {
  public var resources: [PermissionResource]
  public var presets: [PermissionPreset]
  public var accessSurfaces: [AccessSurface]

  public init(
    resources: [PermissionResource],
    presets: [PermissionPreset] = [],
    accessSurfaces: [AccessSurface] = []
  ) {
    self.resources = resources
    self.presets = presets
    self.accessSurfaces = accessSurfaces
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    resources = try container.decodeIfPresent([PermissionResource].self, forKey: .resources) ?? []
    presets = try container.decodeIfPresent([PermissionPreset].self, forKey: .presets) ?? []
    accessSurfaces =
      try container.decodeIfPresent([AccessSurface].self, forKey: .accessSurfaces) ?? []
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
  public var requires: [String]

  public init(
    key: String,
    permission: String,
    label: String,
    description: String? = nil,
    requires: [String] = []
  ) {
    self.key = key
    self.permission = permission
    self.label = label
    self.description = description
    self.requires = requires
  }

  public var id: String { permission }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    key = try container.decode(String.self, forKey: .key)
    permission = try container.decode(String.self, forKey: .permission)
    label = try container.decode(String.self, forKey: .label)
    description = try container.decodeIfPresent(String.self, forKey: .description)
    requires = try container.decodeIfPresent([String].self, forKey: .requires) ?? []
  }
}

public struct PermissionPreset: Codable, Hashable, Sendable, Identifiable {
  public var key: String
  public var label: String
  public var description: String?
  public var permissions: [String]

  public var id: String { key }

  public init(
    key: String,
    label: String,
    description: String? = nil,
    permissions: [String] = []
  ) {
    self.key = key
    self.label = label
    self.description = description
    self.permissions = permissions
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    key = try container.decode(String.self, forKey: .key)
    label = try container.decode(String.self, forKey: .label)
    description = try container.decodeIfPresent(String.self, forKey: .description)
    permissions = try container.decodeIfPresent([String].self, forKey: .permissions) ?? []
  }
}

public enum AccessSurfaceKind: Hashable, Sendable, RawRepresentable, Codable {
  case route
  case settingsCategory
  case customizeCategory
  case landing
  case unknown(String)

  public init?(rawValue: String) {
    switch rawValue {
    case "route": self = .route
    case "settings-category": self = .settingsCategory
    case "customize-category": self = .customizeCategory
    case "landing": self = .landing
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .route: "route"
    case .settingsCategory: "settings-category"
    case .customizeCategory: "customize-category"
    case .landing: "landing"
    case .unknown(let value): value
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self = AccessSurfaceKind(rawValue: try container.decode(String.self)) ?? .unknown("")
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

public enum AccessSurfaceAccessMode: Hashable, Sendable, RawRepresentable, Codable {
  case permissions
  case anyChild
  case unknown(String)

  public init?(rawValue: String) {
    switch rawValue {
    case "permissions": self = .permissions
    case "any-child": self = .anyChild
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .permissions: "permissions"
    case .anyChild: "any-child"
    case .unknown(let value): value
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self = AccessSurfaceAccessMode(rawValue: try container.decode(String.self)) ?? .unknown("")
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

public enum AccessSurfaceMatchMode: Hashable, Sendable, RawRepresentable, Codable {
  case anyOf
  case allOf
  case unknown(String)

  public init?(rawValue: String) {
    switch rawValue {
    case "any-of": self = .anyOf
    case "all-of": self = .allOf
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .anyOf: "any-of"
    case .allOf: "all-of"
    case .unknown(let value): value
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self = AccessSurfaceMatchMode(rawValue: try container.decode(String.self)) ?? .unknown("")
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

public enum AccessSurfaceScopeMode: Hashable, Sendable, RawRepresentable, Codable {
  case globalOnly
  case selectedEnvironmentPlusGlobal
  case anyEffectiveScope
  case unknown(String)

  public init?(rawValue: String) {
    switch rawValue {
    case "global-only": self = .globalOnly
    case "selected-env-plus-global": self = .selectedEnvironmentPlusGlobal
    case "any-effective-scope": self = .anyEffectiveScope
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .globalOnly: "global-only"
    case .selectedEnvironmentPlusGlobal: "selected-env-plus-global"
    case .anyEffectiveScope: "any-effective-scope"
    case .unknown(let value): value
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self = AccessSurfaceScopeMode(rawValue: try container.decode(String.self)) ?? .unknown("")
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

public struct AccessSurface: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var kind: AccessSurfaceKind
  public var url: String?
  public var label: String
  public var accessMode: AccessSurfaceAccessMode
  public var matchMode: AccessSurfaceMatchMode
  public var scopeMode: AccessSurfaceScopeMode
  public var permissions: [String]
  public var children: [String]
  public var fallbackOrder: Int?

  public init(
    id: String,
    kind: AccessSurfaceKind,
    url: String? = nil,
    label: String,
    accessMode: AccessSurfaceAccessMode,
    matchMode: AccessSurfaceMatchMode,
    scopeMode: AccessSurfaceScopeMode,
    permissions: [String] = [],
    children: [String] = [],
    fallbackOrder: Int? = nil
  ) {
    self.id = id
    self.kind = kind
    self.url = url
    self.label = label
    self.accessMode = accessMode
    self.matchMode = matchMode
    self.scopeMode = scopeMode
    self.permissions = permissions
    self.children = children
    self.fallbackOrder = fallbackOrder
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    kind =
      try container.decodeIfPresent(AccessSurfaceKind.self, forKey: .kind) ?? .unknown("")
    url = try container.decodeIfPresent(String.self, forKey: .url)
    label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
    accessMode =
      try container.decodeIfPresent(AccessSurfaceAccessMode.self, forKey: .accessMode)
      ?? .unknown("")
    matchMode =
      try container.decodeIfPresent(AccessSurfaceMatchMode.self, forKey: .matchMode)
      ?? .unknown("")
    scopeMode =
      try container.decodeIfPresent(AccessSurfaceScopeMode.self, forKey: .scopeMode)
      ?? .unknown("")
    permissions = try container.decodeIfPresent([String].self, forKey: .permissions) ?? []
    children = try container.decodeIfPresent([String].self, forKey: .children) ?? []
    fallbackOrder = try container.decodeIfPresent(Int.self, forKey: .fallbackOrder)
  }
}

extension PermissionsManifest {
  /// Adds every transitive `PermissionAction.requires` dependency while
  /// preserving the caller's selection order.
  public func normalizePermissionSelection(_ selected: [String]) -> [String] {
    var requirements: [String: [String]] = [:]
    for resource in resources {
      for action in resource.actions {
        requirements[action.permission] = action.requires
      }
    }

    var seen = Set<String>()
    var normalized: [String] = []
    for permission in selected where seen.insert(permission).inserted {
      normalized.append(permission)
    }

    var index = 0
    while index < normalized.count {
      for required in requirements[normalized[index]] ?? []
      where seen.insert(required).inserted {
        normalized.append(required)
      }
      index += 1
    }
    return normalized
  }

  /// Evaluates backend-owned access metadata for advisory UI gating.
  /// Backend authorization remains authoritative for actual requests.
  public func canAccessSurface(
    id: String,
    user: User,
    selectedEnvironmentID: String? = nil
  ) -> Bool {
    var index: [String: AccessSurface] = [:]
    for surface in accessSurfaces {
      index[surface.id] = surface
    }
    var visiting = Set<String>()
    return canAccessSurfaceInternal(
      id: id,
      user: user,
      selectedEnvironmentID: selectedEnvironmentID,
      index: index,
      visiting: &visiting
    )
  }

  private func canAccessSurfaceInternal(
    id: String,
    user: User,
    selectedEnvironmentID: String?,
    index: [String: AccessSurface],
    visiting: inout Set<String>
  ) -> Bool {
    guard !visiting.contains(id), let surface = index[id] else { return false }

    switch surface.accessMode {
    case .anyChild:
      visiting.insert(id)
      defer { visiting.remove(id) }
      return surface.children.contains { childID in
        canAccessSurfaceInternal(
          id: childID,
          user: user,
          selectedEnvironmentID: selectedEnvironmentID,
          index: index,
          visiting: &visiting
        )
      }
    case .permissions:
      guard !surface.permissions.isEmpty else { return false }
      switch surface.matchMode {
      case .allOf:
        return surface.permissions.allSatisfy {
          userHasPermissionInternal(
            user, permission: $0, scopeMode: surface.scopeMode,
            selectedEnvironmentID: selectedEnvironmentID)
        }
      case .anyOf:
        return surface.permissions.contains {
          userHasPermissionInternal(
            user, permission: $0, scopeMode: surface.scopeMode,
            selectedEnvironmentID: selectedEnvironmentID)
        }
      case .unknown:
        return false
      }
    case .unknown:
      return false
    }
  }

  private func userHasPermissionInternal(
    _ user: User,
    permission: String,
    scopeMode: AccessSurfaceScopeMode,
    selectedEnvironmentID: String?
  ) -> Bool {
    switch scopeMode {
    case .globalOnly:
      return user.hasPermission(permission)
    case .selectedEnvironmentPlusGlobal:
      return user.hasPermission(permission, environmentID: selectedEnvironmentID)
    case .anyEffectiveScope:
      guard let permissionsByEnv = user.permissionsByEnv else {
        return user.isGlobalAdmin
      }
      return permissionsByEnv.values.contains { permissions in
        permissions.contains(Permission.sudo) || permissions.contains(permission)
      }
    case .unknown:
      return false
    }
  }
}
