@testable import Arcane
import Foundation
import XCTest

final class UserDecodingTests: XCTestCase {
    private let decoder = ArcaneJSON.makeDecoder()
    private let encoder = ArcaneJSON.makeEncoder()

    // MARK: - v1 shape

    func testDecodeV1Admin() throws {
        let json = #"""
        {
            "id": "u1",
            "username": "alice",
            "roles": ["admin"],
            "canDelete": true,
            "requiresPasswordChange": false
        }
        """#
        let user = try decoder.decode(User.self, from: Data(json.utf8))
        XCTAssertEqual(user.roles, ["admin"])
        XCTAssertNil(user.roleAssignments)
        XCTAssertNil(user.permissionsByEnv)
        XCTAssertTrue(user.isGlobalAdmin)
        XCTAssertTrue(user.isAdmin)
        XCTAssertTrue(user.hasPermission(Permission.Containers.start))
        XCTAssertTrue(user.hasPermission(Permission.Containers.start, environmentID: "3"))
        XCTAssertTrue(user.hasPermission("anything:goes"))
    }

    func testDecodeV1NonAdmin() throws {
        let json = #"""
        {
            "id": "u2",
            "username": "bob",
            "roles": ["user"],
            "canDelete": true,
            "requiresPasswordChange": false
        }
        """#
        let user = try decoder.decode(User.self, from: Data(json.utf8))
        XCTAssertFalse(user.isGlobalAdmin)
        XCTAssertFalse(user.hasPermission(Permission.Containers.start))
        XCTAssertFalse(user.hasPermission(Permission.Containers.start, environmentID: "3"))
        XCTAssertTrue(user.permissions(forEnvironment: nil).isEmpty)
    }

    // MARK: - v2 shape

    func testDecodeV2AdminGlobal() throws {
        let json = #"""
        {
            "id": "u3",
            "username": "root",
            "roleAssignments": [
                { "roleId": "role_admin", "source": "manual" }
            ],
            "permissionsByEnv": { "global": ["*"] },
            "canDelete": false,
            "requiresPasswordChange": false,
            "createdAt": "2026-01-01T00:00:00Z",
            "updatedAt": "2026-01-01T00:00:00Z"
        }
        """#
        let user = try decoder.decode(User.self, from: Data(json.utf8))
        XCTAssertEqual(user.roles, ["role_admin"]) // synthesized from assignments
        XCTAssertEqual(user.roleAssignments?.count, 1)
        XCTAssertEqual(user.permissionsByEnv?["global"], ["*"])
        XCTAssertTrue(user.isGlobalAdmin)
        XCTAssertTrue(user.isAdmin)
        XCTAssertTrue(user.hasPermission(Permission.Containers.start))
        XCTAssertTrue(user.hasPermission(Permission.Containers.start, environmentID: "any-env"))
        XCTAssertTrue(user.hasPermission("custom:perm"))
    }

    func testDecodeV2EnvScopedDeployer() throws {
        let json = #"""
        {
            "id": "u4",
            "username": "deploy",
            "roleAssignments": [
                { "roleId": "role_deployer", "environmentId": "3", "source": "manual" }
            ],
            "permissionsByEnv": {
                "global": ["dashboard:read"],
                "3": ["containers:start", "containers:stop"]
            },
            "canDelete": true,
            "requiresPasswordChange": false,
            "createdAt": "2026-01-01T00:00:00Z",
            "updatedAt": "2026-01-01T00:00:00Z"
        }
        """#
        let user = try decoder.decode(User.self, from: Data(json.utf8))
        XCTAssertFalse(user.isGlobalAdmin)
        XCTAssertTrue(user.hasPermission(Permission.Containers.start, environmentID: "3"))
        XCTAssertTrue(user.hasPermission(Permission.Containers.stop, environmentID: "3"))
        XCTAssertFalse(user.hasPermission(Permission.Containers.start, environmentID: "4"))
        XCTAssertTrue(user.hasPermission(Permission.Dashboard.read))
        XCTAssertTrue(user.hasPermission(Permission.Dashboard.read, environmentID: "3"))
        XCTAssertFalse(user.hasPermission(Permission.Containers.start)) // global query, only env-scoped
        XCTAssertEqual(user.roles, ["role_deployer"])
    }

    func testDecodeV2NoPerms() throws {
        let json = #"""
        {
            "id": "u5",
            "username": "stranger",
            "roleAssignments": [],
            "permissionsByEnv": {},
            "canDelete": true,
            "requiresPasswordChange": false,
            "createdAt": "2026-01-01T00:00:00Z",
            "updatedAt": "2026-01-01T00:00:00Z"
        }
        """#
        let user = try decoder.decode(User.self, from: Data(json.utf8))
        XCTAssertFalse(user.isGlobalAdmin)
        XCTAssertFalse(user.hasPermission(Permission.Containers.start))
        XCTAssertFalse(user.hasPermission(Permission.Containers.start, environmentID: "3"))
        XCTAssertEqual(user.roles, [])
    }

    func testV2SudoWildcardEnvScoped() throws {
        let json = #"""
        {
            "id": "u6",
            "username": "envadmin",
            "roleAssignments": [
                { "roleId": "role_admin", "environmentId": "3", "source": "manual" }
            ],
            "permissionsByEnv": { "3": ["*"] },
            "canDelete": true,
            "requiresPasswordChange": false,
            "createdAt": "2026-01-01T00:00:00Z",
            "updatedAt": "2026-01-01T00:00:00Z"
        }
        """#
        let user = try decoder.decode(User.self, from: Data(json.utf8))
        XCTAssertFalse(user.isGlobalAdmin) // sudo is env-scoped, not global
        XCTAssertTrue(user.hasPermission("anything:goes", environmentID: "3"))
        XCTAssertFalse(user.hasPermission(Permission.Containers.start, environmentID: "4"))
        XCTAssertFalse(user.hasPermission(Permission.Containers.start)) // global query
    }

    func testV2DedupesRolesAcrossEnvs() throws {
        let json = #"""
        {
            "id": "u7",
            "username": "multi",
            "roleAssignments": [
                { "roleId": "role_viewer", "environmentId": "3", "source": "manual" },
                { "roleId": "role_viewer", "environmentId": "4", "source": "manual" },
                { "roleId": "role_deployer", "environmentId": "5", "source": "oidc" }
            ],
            "permissionsByEnv": {},
            "canDelete": true,
            "requiresPasswordChange": false,
            "createdAt": "2026-01-01T00:00:00Z"
        }
        """#
        let user = try decoder.decode(User.self, from: Data(json.utf8))
        XCTAssertEqual(user.roles, ["role_viewer", "role_deployer"]) // deduped, original order preserved
    }

    // MARK: - ServerCapabilities detection

    func testCapabilitiesDetectV1() throws {
        let user = User(id: "u", username: "a", roles: ["admin"])
        XCTAssertEqual(ServerCapabilities.detect(from: user), .legacyRoles)
    }

    func testCapabilitiesDetectV2WithAssignments() throws {
        let user = User(
            id: "u",
            username: "a",
            roleAssignments: [RoleAssignmentSummary(roleId: "role_admin")]
        )
        XCTAssertEqual(ServerCapabilities.detect(from: user), .rbac)
    }

    func testCapabilitiesDetectV2WithPermissionsOnly() throws {
        let user = User(
            id: "u",
            username: "a",
            permissionsByEnv: ["global": ["*"]]
        )
        XCTAssertEqual(ServerCapabilities.detect(from: user), .rbac)
    }

    // MARK: - Encoding

    func testCreateUserOmitsNilRoles() throws {
        let body = CreateUser(username: "alice", password: "12345678", roles: nil)
        let data = try encoder.encode(body)
        let json = String(decoding: data, as: UTF8.self)
        XCTAssertFalse(json.contains("\"roles\""), "Expected no roles key when nil; got: \(json)")
        XCTAssertTrue(json.contains("\"username\""))
        XCTAssertTrue(json.contains("\"password\""))
    }

    func testCreateUserIncludesRolesWhenSet() throws {
        let body = CreateUser(username: "alice", password: "12345678", roles: ["admin"])
        let data = try encoder.encode(body)
        let json = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(json.contains("\"roles\""))
        XCTAssertTrue(json.contains("\"admin\""))
    }

    func testUpdateUserOmitsNilRoles() throws {
        let body = UpdateUser(displayName: "Alice", roles: nil)
        let data = try encoder.encode(body)
        let json = String(decoding: data, as: UTF8.self)
        XCTAssertFalse(json.contains("\"roles\""))
    }

    // MARK: - Round-trip

    func testRoundTripV2User() throws {
        let original = User(
            id: "u8",
            username: "rt",
            email: "rt@example.com",
            roles: ["role_editor"],
            canDelete: true,
            requiresPasswordChange: false,
            roleAssignments: [
                RoleAssignmentSummary(roleId: "role_editor", environmentId: "3", source: "manual")
            ],
            permissionsByEnv: ["global": ["dashboard:read"], "3": ["containers:start"]]
        )
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(User.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.roleAssignments?.count, 1)
        XCTAssertEqual(decoded.permissionsByEnv?["global"], ["dashboard:read"])
        XCTAssertEqual(decoded.permissionsByEnv?["3"], ["containers:start"])
        XCTAssertTrue(decoded.hasPermission(Permission.Containers.start, environmentID: "3"))
    }
}
