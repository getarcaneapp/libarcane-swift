import Foundation

/// RolesService manages roles and role-related metadata in v2 RBAC servers.
/// Calls fail with `ArcaneError.notFound` on v1 servers; gate UI on
/// `ArcaneClient.serverCapabilities()` to avoid invoking against v1.
public struct RolesService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    /// List roles (built-in + custom) with pagination.
    public func listPaginated(
        search: String? = nil,
        sort: String? = nil,
        order: SortOrder? = nil,
        start: Int = 0,
        limit: Int = 20
    ) async throws -> PaginatedResponse<Role> {
        var query: [URLQueryItem] = []
        if let search { query.append(URLQueryItem(name: "search", value: search)) }
        if let sort { query.append(URLQueryItem(name: "sort", value: sort)) }
        if let order { query.append(URLQueryItem(name: "order", value: order.rawValue)) }
        return try await rest.transport.paginated("roles", start: start, limit: limit, query: query)
    }

    /// Get a single role by ID.
    public func get(id: String) async throws -> Role {
        try await rest.get("roles/\(id)")
    }

    /// Create a custom role. Reserved for global admins server-side.
    public func create(_ body: CreateRole) async throws -> Role {
        try await rest.post("roles", body: body)
    }

    /// Update a custom role. Built-in roles return 403.
    public func update(id: String, body: UpdateRole) async throws -> Role {
        try await rest.put("roles/\(id)", body: body)
    }

    /// Delete a custom role. May throw `.conflict` if removal would leave
    /// the system with zero global admins.
    public func delete(id: String) async throws {
        try await rest.deleteVoid("roles/\(id)")
    }

    /// Returns the server's permission manifest — every recognized
    /// permission grouped by resource. Used to render the permission picker.
    public func availablePermissions() async throws -> PermissionsManifest {
        try await rest.get("roles/available-permissions")
    }
}
