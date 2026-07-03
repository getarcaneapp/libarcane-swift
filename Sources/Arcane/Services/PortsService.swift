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
