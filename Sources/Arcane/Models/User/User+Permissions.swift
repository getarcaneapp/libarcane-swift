import Foundation

extension User {
  /// Reserved key in `permissionsByEnv` that holds permissions applying
  /// across every environment and to org-level endpoints.
  public static let globalPermissionsKey = "global"

  /// True iff this user holds a global `role_admin` assignment (v2), has
  /// the sudo wildcard `"*"` in their global permissions (v2), or has
  /// `"admin"` in the legacy `roles` array (v1).
  public var isGlobalAdmin: Bool {
    if let assignments = roleAssignments {
      let adminGlobally = assignments.contains { assignment in
        assignment.roleId == Role.BuiltIn.admin && assignment.environmentId == nil
      }
      if adminGlobally { return true }
    }
    if let perms = permissionsByEnv?[User.globalPermissionsKey],
      perms.contains(Permission.sudo)
    {
      return true
    }
    return roles.contains("admin")
  }

  /// Backward-compat alias for `isGlobalAdmin`. Existing call sites reading
  /// `user.isAdmin` against either a v1 or a v2 server get the same
  /// semantic answer.
  public var isAdmin: Bool { isGlobalAdmin }

  /// All permissions the user effectively holds for the given environment.
  /// Pass `nil` for "global / org-level only".
  ///
  /// - **v2**: union of `permissionsByEnv["global"]` and (if envID != nil)
  ///   `permissionsByEnv[envID]`.
  /// - **v1**: admins receive `[Permission.sudo]` (so `hasPermission`
  ///   returns true for any check via the wildcard); non-admins receive an
  ///   empty set.
  public func permissions(forEnvironment envID: String?) -> Set<String> {
    if let perms = permissionsByEnv {
      var out = Set(perms[User.globalPermissionsKey] ?? [])
      if let envID, let envPerms = perms[envID] {
        out.formUnion(envPerms)
      }
      return out
    }
    return isGlobalAdmin ? [Permission.sudo] : []
  }

  /// Whether the user holds `perm` for the given environment. Pass
  /// `environmentID: nil` to check only the global bucket.
  ///
  /// Returns `true` unconditionally if any in-scope bucket contains the
  /// sudo wildcard `"*"`.
  public func hasPermission(_ perm: String, environmentID: String? = nil) -> Bool {
    let bucket = permissions(forEnvironment: environmentID)
    if bucket.contains(Permission.sudo) { return true }
    return bucket.contains(perm)
  }

  /// Whether the user holds any of `perms` for the given environment.
  public func hasAnyPermission(_ perms: [String], environmentID: String? = nil) -> Bool {
    let bucket = permissions(forEnvironment: environmentID)
    if bucket.contains(Permission.sudo) { return true }
    return perms.contains(where: bucket.contains)
  }
}
