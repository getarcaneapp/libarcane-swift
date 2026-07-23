import Foundation
import XCTest

@testable import Arcane

final class RoleModelsTests: XCTestCase {
  private let decoder = ArcaneJSON.makeDecoder()
  private let encoder = ArcaneJSON.makeEncoder()

  func testDecodeRole() throws {
    let json = #"""
      {
          "id": "role_admin",
          "name": "Admin",
          "description": "Full administrative access",
          "permissions": ["*"],
          "builtIn": true,
          "assignedUserCount": 2,
          "createdAt": "2026-01-01T00:00:00Z"
      }
      """#
    let role = try decoder.decode(Role.self, from: Data(json.utf8))
    XCTAssertEqual(role.id, Role.BuiltIn.admin)
    XCTAssertEqual(role.name, "Admin")
    XCTAssertEqual(role.permissions, ["*"])
    XCTAssertTrue(role.builtIn)
    XCTAssertEqual(role.assignedUserCount, 2)
    XCTAssertNil(role.updatedAt)
  }

  func testRoleDefaultsMissingFields() throws {
    let json = #"""
      {
          "id": "role_custom",
          "name": "Custom",
          "createdAt": "2026-01-01T00:00:00Z"
      }
      """#
    let role = try decoder.decode(Role.self, from: Data(json.utf8))
    XCTAssertEqual(role.permissions, [])
    XCTAssertFalse(role.builtIn)
    XCTAssertEqual(role.assignedUserCount, 0)
  }

  func testDecodeRoleAssignment() throws {
    let json = #"""
      {
          "id": "a1",
          "userId": "u1",
          "roleId": "role_deployer",
          "environmentId": "3",
          "source": "manual",
          "createdAt": "2026-01-01T00:00:00Z"
      }
      """#
    let assignment = try decoder.decode(RoleAssignment.self, from: Data(json.utf8))
    XCTAssertEqual(assignment.environmentId, "3")
    XCTAssertEqual(assignment.sourceKind, .manual)
  }

  func testDecodeGlobalRoleAssignment() throws {
    let json = #"""
      {
          "id": "a2",
          "userId": "u1",
          "roleId": "role_admin",
          "source": "oidc",
          "createdAt": "2026-01-01T00:00:00Z"
      }
      """#
    let assignment = try decoder.decode(RoleAssignment.self, from: Data(json.utf8))
    XCTAssertNil(assignment.environmentId)
    XCTAssertEqual(assignment.sourceKind, .oidc)
  }

  func testDecodeOidcRoleMapping() throws {
    let json = #"""
      {
          "id": "m1",
          "claimValue": "docker-admins",
          "roleId": "role_admin",
          "source": "manual",
          "createdAt": "2026-01-01T00:00:00Z"
      }
      """#
    let mapping = try decoder.decode(OidcRoleMapping.self, from: Data(json.utf8))
    XCTAssertEqual(mapping.claimValue, "docker-admins")
    XCTAssertNil(mapping.environmentId)
    XCTAssertEqual(mapping.sourceKind, .manual)
  }

  func testDecodeEnvDeclaredOidcMapping() throws {
    let json = #"""
      {
          "id": "m2",
          "claimValue": "viewers",
          "roleId": "role_viewer",
          "environmentId": "3",
          "source": "env",
          "createdAt": "2026-01-01T00:00:00Z"
      }
      """#
    let mapping = try decoder.decode(OidcRoleMapping.self, from: Data(json.utf8))
    XCTAssertEqual(mapping.sourceKind, .env)
    XCTAssertEqual(mapping.environmentId, "3")
  }

  func testDecodePermissionsManifest() throws {
    let json = #"""
      {
          "resources": [
              {
                  "key": "containers",
                  "label": "Containers",
                  "scope": "env",
                  "actions": [
                      { "key": "start", "permission": "containers:start", "label": "Start" },
                      { "key": "stop", "permission": "containers:stop", "label": "Stop", "description": "Stop a container", "requires": ["containers:read"] }
                  ]
              },
              {
                  "key": "users",
                  "label": "Users",
                  "scope": "global",
                  "actions": [
                      { "key": "list", "permission": "users:list", "label": "List" }
                  ]
              }
          ],
          "presets": [
              { "key": "operator", "label": "Operator", "permissions": ["containers:start", "containers:stop"] }
          ],
          "accessSurfaces": [
              {
                  "id": "route.containers",
                  "kind": "route",
                  "url": "/containers",
                  "label": "Containers",
                  "accessMode": "permissions",
                  "matchMode": "any-of",
                  "scopeMode": "selected-env-plus-global",
                  "permissions": ["containers:read"],
                  "fallbackOrder": 20
              }
          ]
      }
      """#
    let manifest = try decoder.decode(PermissionsManifest.self, from: Data(json.utf8))
    XCTAssertEqual(manifest.resources.count, 2)
    XCTAssertEqual(manifest.resources[0].scopeKind, .env)
    XCTAssertEqual(manifest.resources[1].scopeKind, .global)
    XCTAssertEqual(manifest.resources[0].actions[1].description, "Stop a container")
    XCTAssertEqual(manifest.resources[0].actions[1].requires, ["containers:read"])
    XCTAssertEqual(manifest.presets.first?.permissions, ["containers:start", "containers:stop"])
    XCTAssertEqual(manifest.accessSurfaces.first?.kind, .route)
    XCTAssertEqual(manifest.accessSurfaces.first?.scopeMode, .selectedEnvironmentPlusGlobal)
    XCTAssertEqual(manifest.accessSurfaces.first?.fallbackOrder, 20)
  }

  func testNormalizePermissionSelectionAddsTransitiveRequirementsOnce() {
    let manifest = PermissionsManifest(resources: [
      PermissionResource(
        key: "containers",
        label: "Containers",
        scope: "env",
        actions: [
          PermissionAction(
            key: "create",
            permission: "containers:create",
            label: "Create",
            requires: ["containers:read"]
          ),
          PermissionAction(
            key: "read",
            permission: "containers:read",
            label: "Read",
            requires: ["containers:list"]
          ),
          PermissionAction(
            key: "list",
            permission: "containers:list",
            label: "List",
            requires: ["containers:create"]
          ),
        ]
      )
    ])

    XCTAssertEqual(
      manifest.normalizePermissionSelection(["containers:create", "containers:create"]),
      ["containers:create", "containers:read", "containers:list"]
    )
  }

  func testAccessSurfaceEvaluationUsesBackendModesAndFailsClosed() {
    let manifest = PermissionsManifest(
      resources: [],
      accessSurfaces: [
        AccessSurface(
          id: "route.global",
          kind: .route,
          label: "Global",
          accessMode: .permissions,
          matchMode: .allOf,
          scopeMode: .globalOnly,
          permissions: ["dashboard:read"]
        ),
        AccessSurface(
          id: "route.environment",
          kind: .route,
          label: "Environment",
          accessMode: .permissions,
          matchMode: .allOf,
          scopeMode: .selectedEnvironmentPlusGlobal,
          permissions: ["containers:list", "containers:read"]
        ),
        AccessSurface(
          id: "route.any-scope",
          kind: .route,
          label: "Any scope",
          accessMode: .permissions,
          matchMode: .anyOf,
          scopeMode: .anyEffectiveScope,
          permissions: ["containers:read"]
        ),
        AccessSurface(
          id: "landing.main",
          kind: .landing,
          label: "Main",
          accessMode: .anyChild,
          matchMode: .anyOf,
          scopeMode: .selectedEnvironmentPlusGlobal,
          children: ["route.environment"]
        ),
        AccessSurface(
          id: "future",
          kind: .unknown("panel"),
          label: "Future",
          accessMode: .unknown("policy-v2"),
          matchMode: .unknown("threshold"),
          scopeMode: .unknown("organization"),
          permissions: ["dashboard:read"]
        ),
        AccessSurface(
          id: "cycle.a",
          kind: .landing,
          label: "Cycle A",
          accessMode: .anyChild,
          matchMode: .anyOf,
          scopeMode: .globalOnly,
          children: ["cycle.b"]
        ),
        AccessSurface(
          id: "cycle.b",
          kind: .landing,
          label: "Cycle B",
          accessMode: .anyChild,
          matchMode: .anyOf,
          scopeMode: .globalOnly,
          children: ["cycle.a"]
        ),
      ]
    )
    let user = User(
      id: "u1",
      username: "operator",
      permissionsByEnv: [
        "global": ["dashboard:read"],
        "edge_1": ["containers:list", "containers:read"],
      ]
    )

    XCTAssertTrue(manifest.canAccessSurface(id: "route.global", user: user))
    XCTAssertTrue(
      manifest.canAccessSurface(
        id: "route.environment", user: user, selectedEnvironmentID: "edge_1")
    )
    XCTAssertFalse(
      manifest.canAccessSurface(
        id: "route.environment", user: user, selectedEnvironmentID: "edge_2")
    )
    XCTAssertTrue(manifest.canAccessSurface(id: "route.any-scope", user: user))
    XCTAssertTrue(
      manifest.canAccessSurface(id: "landing.main", user: user, selectedEnvironmentID: "edge_1")
    )
    XCTAssertFalse(manifest.canAccessSurface(id: "future", user: user))
    XCTAssertFalse(manifest.canAccessSurface(id: "cycle.a", user: user))
    XCTAssertFalse(manifest.canAccessSurface(id: "missing", user: user))

    let globalSudoUser = User(
      id: "sudo-global",
      username: "global-admin",
      permissionsByEnv: ["global": [Permission.sudo]]
    )
    XCTAssertTrue(manifest.canAccessSurface(id: "route.global", user: globalSudoUser))
    XCTAssertTrue(
      manifest.canAccessSurface(
        id: "route.environment",
        user: globalSudoUser,
        selectedEnvironmentID: "edge_1"
      )
    )
    XCTAssertTrue(manifest.canAccessSurface(id: "route.any-scope", user: globalSudoUser))
    XCTAssertTrue(
      manifest.canAccessSurface(
        id: "landing.main",
        user: globalSudoUser,
        selectedEnvironmentID: "edge_1"
      )
    )

    let environmentSudoUser = User(
      id: "sudo-environment",
      username: "environment-admin",
      permissionsByEnv: ["edge_1": [Permission.sudo]]
    )
    XCTAssertFalse(manifest.canAccessSurface(id: "route.global", user: environmentSudoUser))
    XCTAssertTrue(
      manifest.canAccessSurface(
        id: "route.environment",
        user: environmentSudoUser,
        selectedEnvironmentID: "edge_1"
      )
    )
    XCTAssertTrue(manifest.canAccessSurface(id: "route.any-scope", user: environmentSudoUser))
    XCTAssertTrue(
      manifest.canAccessSurface(
        id: "landing.main",
        user: environmentSudoUser,
        selectedEnvironmentID: "edge_1"
      )
    )
  }

  func testSetUserAssignmentsEncoding() throws {
    let body = SetUserAssignments(assignments: [
      UserAssignmentInput(roleId: Role.BuiltIn.admin),
      UserAssignmentInput(roleId: Role.BuiltIn.deployer, environmentId: "3"),
    ])
    let data = try encoder.encode(body)
    let decoded = try decoder.decode(SetUserAssignments.self, from: data)
    XCTAssertEqual(decoded.assignments.count, 2)
    XCTAssertNil(decoded.assignments[0].environmentId)
    XCTAssertEqual(decoded.assignments[1].environmentId, "3")
  }

  func testPermissionConstants() {
    XCTAssertEqual(Permission.Containers.start, "containers:start")
    XCTAssertEqual(Permission.Roles.list, "roles:list")
    XCTAssertEqual(Permission.GitRepositories.sync, "git-repositories:sync")
    XCTAssertEqual(Permission.Variables.read, "variables:read")
    XCTAssertEqual(Permission.Variables.create, "variables:create")
    XCTAssertEqual(Permission.Variables.update, "variables:update")
    XCTAssertEqual(Permission.Variables.delete, "variables:delete")
    XCTAssertEqual(Permission.Variables.sync, "variables:sync")
    XCTAssertEqual(Permission.Events.delete, "events:delete")
    XCTAssertEqual(Permission.sudo, "*")
    XCTAssertEqual(Role.BuiltIn.admin, "role_admin")
  }
}
