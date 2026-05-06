import Foundation

public struct ImagesService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    public func list(envID: EnvironmentID? = nil, page: Int = 1, pageSize: Int = 50) async throws -> PaginatedResponse<ImageSummary> {
        try await rest.transport.paginated(rest.environmentPath(envID, "images"), page: page, pageSize: pageSize)
    }

    public func listAll(envID: EnvironmentID? = nil, pageSize: Int = 100) -> ArcanePaginator<ImageSummary> {
        ArcanePaginator { page in
            try await list(envID: envID, page: page, pageSize: pageSize)
        }
    }
}
