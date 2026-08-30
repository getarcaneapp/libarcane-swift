import Foundation

/// Snapshot of which Arcane API shape the server speaks. Populated from the
/// first authenticated `User` payload the SDK decodes (login, `auth/me`, or
/// any OIDC callback). Surfaced via `ArcaneClient.serverCapabilities()` so
/// callers can conditionally show v2-only screens such as the role manager.
public struct ServerCapabilities: Hashable, Sendable {
  public enum Mode: String, Hashable, Sendable {
    /// Detection has not yet happened (no user payload has been decoded).
    case unknown
    /// Legacy string-roles backend. `User.roles` is the source of truth;
    /// permission helpers fall back to admin/non-admin.
    case legacyRoles
    /// RBAC backend with role assignments + per-env permission sets and
    /// the `/roles`, `/oidc/role-mappings` endpoints.
    case rbac
  }

  public var mode: Mode

  /// Feature flags advertised by `/app-version` `enabledFeatures`, recorded by
  /// `VersionService.appVersion()`.
  public var enabledFeatures: Set<String>

  public init(mode: Mode, enabledFeatures: Set<String> = []) {
    self.mode = mode
    self.enabledFeatures = enabledFeatures
  }

  /// True iff the server advertises `mobile-push-v1` (the `/apns` endpoints).
  public var supportsMobilePush: Bool { enabledFeatures.contains(mobilePushFeature) }

  /// True iff the server exposes the v2 RBAC endpoints.
  public var supportsRoleManagement: Bool { mode == .rbac }

  /// True iff the server exposes the v2 background activity endpoints.
  public var supportsActivities: Bool { mode == .rbac }

  /// True iff payloads include `permissionsByEnv` so per-permission queries
  /// return non-trivial answers for non-admin users.
  public var supportsPermissionQueries: Bool { mode == .rbac }

  public static let unknown = ServerCapabilities(mode: .unknown)

  /// Infers the server mode from a freshly decoded `User`. `permissionsByEnv`
  /// is the canonical v2 signal; `roleAssignments` is treated as a fallback.
  public static func detect(from user: User) -> Mode {
    if user.permissionsByEnv != nil || user.roleAssignments != nil { return .rbac }
    return .legacyRoles
  }
}
