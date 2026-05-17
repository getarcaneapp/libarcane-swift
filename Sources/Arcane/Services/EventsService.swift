import Foundation

/// EventsService manages system audit events.
public struct EventsService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    /// List system events with pagination and optional filters.
    public func listPaginated(
        search: String? = nil,
        sort: String? = nil,
        order: SortOrder? = nil,
        start: Int = 0,
        limit: Int = 20,
        severity: String? = nil,
        type: String? = nil
    ) async throws -> PaginatedResponse<Event> {
        let query = buildEventQuery(
            search: search,
            sort: sort,
            order: order,
            start: start,
            limit: limit,
            severity: severity,
            type: type
        )
        return try await rest.transport.paginated("events", start: start, limit: limit, query: query)
    }

    /// List events scoped to a specific environment ID.
    public func listByEnvironmentPaginated(
        environmentID: String,
        search: String? = nil,
        sort: String? = nil,
        order: SortOrder? = nil,
        start: Int = 0,
        limit: Int = 20,
        severity: String? = nil,
        type: String? = nil
    ) async throws -> PaginatedResponse<Event> {
        let query = buildEventQuery(
            search: search,
            sort: sort,
            order: order,
            start: start,
            limit: limit,
            severity: severity,
            type: type
        )
        return try await rest.transport.paginated("events/environment/\(environmentID)", start: start, limit: limit, query: query)
    }

    /// Create a new event.
    public func create(_ body: CreateEvent) async throws -> Event {
        try await rest.post("events", body: body)
    }

    /// Delete an event by ID.
    public func delete(id: String) async throws {
        try await rest.deleteVoid("events/\(id)")
    }

    private func buildEventQuery(
        search: String?,
        sort: String?,
        order: SortOrder?,
        start: Int,
        limit: Int,
        severity: String?,
        type: String?
    ) -> [URLQueryItem] {
        var query: [URLQueryItem] = []
        if let search { query.append(URLQueryItem(name: "search", value: search)) }
        if let sort { query.append(URLQueryItem(name: "sort", value: sort)) }
        if let order { query.append(URLQueryItem(name: "order", value: order.rawValue)) }
        if let severity { query.append(URLQueryItem(name: "severity", value: severity)) }
        if let type { query.append(URLQueryItem(name: "type", value: type)) }
        return query
    }
}
