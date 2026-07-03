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
                      { "key": "stop", "permission": "containers:stop", "label": "Stop", "description": "Stop a container" }
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
          ]
      }
      """#
    let manifest = try decoder.decode(PermissionsManifest.self, from: Data(json.utf8))
    XCTAssertEqual(manifest.resources.count, 2)
    XCTAssertEqual(manifest.resources[0].scopeKind, .env)
    XCTAssertEqual(manifest.resources[1].scopeKind, .global)
    XCTAssertEqual(manifest.resources[0].actions[1].description, "Stop a container")
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
    XCTAssertEqual(Permission.sudo, "*")
    XCTAssertEqual(Role.BuiltIn.admin, "role_admin")
  }
}
