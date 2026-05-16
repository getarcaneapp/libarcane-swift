import Foundation

public struct PortsService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    /// Paginated list of port mappings across containers in an environment.
    public func list(
        envID: EnvironmentID? = nil,
        query: SearchPaginationSort = .init()
    ) async throws -> PaginatedResponse<PortMapping> {
        try await rest.paginated(
            rest.environmentPath(envID, "ports"),
            start: query.start ?? 0,
            limit: query.limit ?? 20,
            query: query.nonPaginationQueryItems
        )
    }
}

extension SearchPaginationSort {
    /// `queryItems` minus the pagination fields, suitable for callers that pass
    /// `page` / `itemsPerPage` as explicit arguments (e.g. `rest.paginated`).
    var nonPaginationQueryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let search { items.append(URLQueryItem(name: "search", value: search)) }
        if let sortBy { items.append(URLQueryItem(name: "sort", value: sortBy)) }
        if let sortOrder { items.append(URLQueryItem(name: "order", value: sortOrder.rawValue)) }
        return items
    }
}
