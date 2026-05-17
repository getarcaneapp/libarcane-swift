import Foundation

/// APIKeysService manages API keys for programmatic access.
public struct APIKeysService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    /// List API keys with pagination.
    public func listPaginated(
        search: String? = nil,
        sort: String? = nil,
        order: SortOrder? = nil,
        start: Int = 0,
        limit: Int = 20
    ) async throws -> PaginatedResponse<APIKey> {
        var query: [URLQueryItem] = []
        if let search { query.append(URLQueryItem(name: "search", value: search)) }
        if let sort { query.append(URLQueryItem(name: "sort", value: sort)) }
        if let order { query.append(URLQueryItem(name: "order", value: order.rawValue)) }
        return try await rest.transport.paginated("api-keys", start: start, limit: limit, query: query)
    }

    /// Get details of a specific API key.
    public func get(id: String) async throws -> APIKey {
        try await rest.get("api-keys/\(id)")
    }

    /// Create a new API key. The plain-text key is returned only on creation.
    public func create(_ body: CreateAPIKey) async throws -> APIKeyCreated {
        try await rest.post("api-keys", body: body)
    }

    /// Update an existing API key.
    public func update(id: String, body: UpdateAPIKey) async throws -> APIKey {
        try await rest.put("api-keys/\(id)", body: body)
    }

    /// Delete an API key.
    public func delete(id: String) async throws {
        try await rest.deleteVoid("api-keys/\(id)")
    }
}
