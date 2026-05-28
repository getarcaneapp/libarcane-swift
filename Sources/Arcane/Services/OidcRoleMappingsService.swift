import Foundation

/// OidcRoleMappingsService manages OIDC claim-value → role mappings.
/// Mappings with `source == "env"` are declared via the
/// `OIDC_ROLE_MAPPINGS` env var and are read-only at runtime (update/delete
/// against them return 403). Available only on v2 RBAC servers.
public struct OidcRoleMappingsService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    /// List every OIDC role mapping. Not paginated.
    public func list() async throws -> [OidcRoleMapping] {
        try await rest.get("oidc/role-mappings")
    }

    public func create(_ body: CreateOidcRoleMapping) async throws -> OidcRoleMapping {
        try await rest.post("oidc/role-mappings", body: body)
    }

    public func update(id: String, body: UpdateOidcRoleMapping) async throws -> OidcRoleMapping {
        try await rest.put("oidc/role-mappings/\(id)", body: body)
    }

    public func delete(id: String) async throws {
        try await rest.deleteVoid("oidc/role-mappings/\(id)")
    }
}
