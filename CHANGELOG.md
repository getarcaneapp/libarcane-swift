# Changelog

All notable changes to libarcane-swift will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `DashboardService.stream(debugAllGood:)` — consumes the aggregated
  `GET /dashboard/stream` NDJSON endpoint (Arcane #2901), multiplexing
  per-environment dashboard snapshots over one connection.
- `DashboardStreamEvent`, `DashboardStreamEventType`, and
  `DashboardStreamErrorCode` models (unknown-tolerant enums; `agent_incompatible`
  and `unreachable` error codes mapped).
- `DashboardSnapshot.versionInfo` — optional per-environment Arcane version
  metadata (`VersionInfo`) carried by snapshots.
- `Environment.lastEdgeTransport` — most recently used edge tunnel transport,
  persisted server-side across disconnects.

### Changed

- `DashboardSnapshotContainers.data` and `DashboardSnapshotImages.data` now
  tolerate the explicit JSON `null` sent by trimmed stream snapshots, decoding
  to an empty array.
- `ActionItemKind` and `ActionItemSeverity` are now unknown-tolerant enums
  (new `.unknown(String)` case) so action items from newer servers can never
  fail snapshot decoding — a single undecodable line ends an NDJSON stream.
  Exhaustive switches over these enums need an `.unknown` case.

- The package manifest now requires Swift `6.3`, and the documented toolchain
  floor matches the current CI contract.
- Transport and websocket internals now centralize auth header application and
  refresh retry behavior without adding parallel helper paths, and websocket
  streams close their underlying connection promptly when iteration stops.
- Websocket log, stats, and terminal streams now use the configured
  `ArcaneClient.Configuration.urlSession`, matching the rest of the transport
  path for direct HTTP and local-network environments.
- `ArcaneJSON` reuses a synchronized ISO-8601 parser cache instead of creating
  fresh formatters for every decoded date string while preserving the existing
  fractional-seconds fallback behavior.
- CI verification now prints the active Swift toolchain and runs `swift build`,
  `swift test`, and `swiftlint lint` before success is claimed.

## [0.1.7] - 2026-05-27

### Added

- **Arcane v2 RBAC support** alongside continued v1 (legacy string roles)
  compatibility. The SDK auto-detects which server shape it's talking to from
  the first authenticated `User` payload it decodes.
- New `Role` model namespace under `Sources/Arcane/Models/Role/`:
  - `Role`, `CreateRole`, `UpdateRole`
  - `RoleAssignment`, `RoleAssignmentSummary`, `UserAssignmentInput`, `SetUserAssignments`, `RoleAssignmentSource` enum
  - `OidcRoleMapping`, `CreateOidcRoleMapping`, `UpdateOidcRoleMapping`, `OidcRoleMappingSource` enum
  - `PermissionsManifest`, `PermissionResource`, `PermissionAction`, `PermissionResourceScope` enum
  - `ApiKeyPermissionGrant`
  - `Role.BuiltIn` constants: `admin`, `editor`, `noShellEditor`, `deployer`, `monitor`, `viewer`
- `Permission` enum namespace with constants for every well-known permission
  string (`Permission.Containers.start`, `Permission.Users.delete`, etc.) plus
  the sudo wildcard `Permission.sudo`. Free-form permission strings are still
  accepted by all helpers.
- `ServerCapabilities` value exposed via `await client.serverCapabilities()`.
  Reports `.legacyRoles`, `.rbac`, or `.unknown`; populated by `AuthManager`
  on every flow that yields a fresh `User` (login, `auth/me`, OIDC callback,
  OIDC device token).
- New services on `ArcaneClient`:
  - `client.roles` — full CRUD for custom roles, plus
    `availablePermissions()` for the permission manifest used by role-editor UIs.
  - `client.oidcRoleMappings` — CRUD for OIDC claim → role mappings.
- New methods on `UsersService`:
  - `getRoleAssignments(userId:)` → `[RoleAssignment]`
  - `setRoleAssignments(userId:assignments:)` → `[RoleAssignment]`
    (replaces every `source == "manual"` assignment; `source == "oidc"`
    rows are preserved server-side).
- Permission helpers on `User`:
  - `isGlobalAdmin` — global `role_admin` assignment, sudo `*` in global perms, or legacy `"admin"` string role.
  - `isAdmin` — backward-compat alias for `isGlobalAdmin`.
  - `permissions(forEnvironment:)` — union of global perms and the queried env's perms.
  - `hasPermission(_:environmentID:)` and `hasAnyPermission(_:environmentID:)` — short-circuits on sudo wildcard.
- Tests covering v1/v2 decoding, env-scoped permission resolution, sudo
  wildcard, role synthesis from assignments, `ServerCapabilities.detect`,
  and `CreateUser`/`UpdateUser` wire encoding (`Tests/ArcaneTests/UserDecodingTests.swift`, `Tests/ArcaneTests/RoleModelsTests.swift`).

### Changed

- `User` now decodes both legacy (`roles: [String]`) and v2 (`roleAssignments`,
  `permissionsByEnv`) shapes via a custom `init(from:)`. On v2 payloads,
  `User.roles` is synthesized as a deduped list of role IDs from
  `roleAssignments` so existing call sites (e.g. `user.roles.contains(...)`)
  keep working without changes.
- `User` gains optional `roleAssignments: [RoleAssignmentSummary]?` and
  `permissionsByEnv: [String: [String]]?` properties. Both are `nil` on v1
  servers.

### Notes for callers

- `CreateUser.roles` and `UpdateUser.roles` remain `[String]?`. On v1 servers,
  pass `["admin"]` / `["user"]` as before. On v2 (RBAC) servers, pass `nil`
  and call `client.users.setRoleAssignments(userId:assignments:)` afterwards
  to grant assignments — the v2 backend rejects unknown body fields.
- Existing `user.isAdmin` checks continue to compile and produce the right
  answer on both v1 and v2 servers (v2 backfills legacy admins into a global
  `role_admin` assignment, which `isGlobalAdmin` recognizes).

[0.1.7]: https://github.com/getarcaneapp/libarcane-swift/releases/tag/v0.1.7
