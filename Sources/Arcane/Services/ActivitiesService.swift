import Foundation

/// ActivitiesService manages v2 background activity lists, details, streams,
/// cancellation, and history cleanup.
public struct ActivitiesService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    /// List current and recent background activities for an environment.
    public func listPaginated(
        envID: EnvironmentID? = nil,
        search: String? = nil,
        sort: String? = nil,
        order: SortOrder? = nil,
        start: Int = 0,
        limit: Int = 50,
        status: ActivityStatus? = nil,
        type: ActivityType? = nil,
        resourceType: String? = nil
    ) async throws -> PaginatedResponse<Activity> {
        try await rest.transport.paginated(
            rest.environmentPath(envID, "activities"),
            start: start,
            limit: limit,
            query: ActivityListFilters(
                search: search,
                sort: sort,
                order: order,
                status: status,
                type: type,
                resourceType: resourceType
            ).queryItems
        )
    }

    /// Get a background activity with its recent output messages.
    public func detail(
        envID: EnvironmentID? = nil,
        activityID: String,
        limit: Int = 500
    ) async throws -> ActivityDetail {
        try await rest.get(
            rest.environmentPath(envID, "activities/\(activityID)"),
            query: [URLQueryItem(name: "limit", value: "\(limit)")]
        )
    }

    /// Stream activity snapshots and updates as NDJSON.
    public func stream(
        envID: EnvironmentID? = nil,
        limit: Int = 50
    ) -> NDJSONStream<ActivityStreamEvent> {
        NDJSONStream(
            transport: rest.transport,
            path: rest.environmentPath(envID, "activities/stream"),
            method: "GET",
            body: nil,
            contentType: nil,
            query: [URLQueryItem(name: "limit", value: "\(limit)")]
        )
    }

    /// Request cancellation for a running or queued activity.
    public func cancel(
        envID: EnvironmentID? = nil,
        activityID: String,
        requestedBy: String? = nil
    ) async throws -> Activity {
        var query: [URLQueryItem] = []
        if let requestedBy, !requestedBy.isEmpty {
            query.append(URLQueryItem(name: "requestedBy", value: requestedBy))
        }
        return try await rest.post(
            rest.environmentPath(envID, "activities/\(activityID)/cancel"),
            body: Optional<EmptyBody>.none,
            query: query
        )
    }

    /// Clear completed activity history for an environment.
    public func clearHistory(envID: EnvironmentID? = nil) async throws -> ClearActivityHistoryResult {
        try await rest.delete(rest.environmentPath(envID, "activities/history"))
    }

    private struct ActivityListFilters {
        let search: String?
        let sort: String?
        let order: SortOrder?
        let status: ActivityStatus?
        let type: ActivityType?
        let resourceType: String?

        var queryItems: [URLQueryItem] {
            var items: [URLQueryItem] = []
            if let search, !search.isEmpty { items.append(URLQueryItem(name: "search", value: search)) }
            if let sort, !sort.isEmpty { items.append(URLQueryItem(name: "sort", value: sort)) }
            if let order { items.append(URLQueryItem(name: "order", value: order.rawValue)) }
            if let status { items.append(URLQueryItem(name: "status", value: status.rawValue)) }
            if let type { items.append(URLQueryItem(name: "type", value: type.rawValue)) }
            if let resourceType, !resourceType.isEmpty {
                items.append(URLQueryItem(name: "resourceType", value: resourceType))
            }
            return items
        }
    }
}
