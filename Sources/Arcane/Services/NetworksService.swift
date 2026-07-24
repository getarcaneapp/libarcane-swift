import Foundation

/// NetworksService exposes the Docker network endpoints registered under
/// ``/environments/{id}/networks`` including topology and prune.
public struct NetworksService: Sendable {
  private let rest: RESTService

  init(rest: RESTService) {
    self.rest = rest
  }

  /// Paginated list of networks.
  public func list(
    envID: EnvironmentID? = nil,
    query: SearchPaginationSort = .init(),
    inUse: Bool? = nil
  ) async throws -> PaginatedResponse<NetworkSummary> {
    var items = query.nonPaginationQueryItems
    if let inUse {
      items.append(URLQueryItem(name: "inUse", value: inUse ? "true" : "false"))
    }
    return try await rest.paginated(
      rest.environmentPath(envID, "networks"),
      start: query.start ?? 0,
      limit: query.limit ?? 20,
      query: items
    )
  }

  /// Get aggregate usage counts for networks.
  public func counts(envID: EnvironmentID? = nil) async throws -> NetworkUsageCounts {
    try await rest.get(rest.environmentPath(envID, "networks/counts"))
  }

  /// Build the network/container topology graph.
  public func topology(envID: EnvironmentID? = nil) async throws -> NetworkTopology {
    try await rest.get(rest.environmentPath(envID, "networks/topology"))
  }

  /// Inspect a network by ID.
  public func inspect(
    envID: EnvironmentID? = nil,
    networkID: String,
    sort: String? = nil,
    order: SortOrder? = nil
  ) async throws -> NetworkInspect {
    var items: [URLQueryItem] = []
    if let sort {
      items.append(URLQueryItem(name: "sort", value: sort))
    }
    if let order {
      items.append(URLQueryItem(name: "order", value: order.rawValue))
    }
    return try await rest.get(
      rest.environmentPath(envID, "networks/\(networkID)"),
      query: items
    )
  }

  /// Create a new Docker network.
  public func create(
    envID: EnvironmentID? = nil,
    request: NetworkCreateRequest
  ) async throws -> NetworkCreateResponse {
    try await rest.post(rest.environmentPath(envID, "networks"), body: request)
  }

  /// Delete a network.
  @discardableResult
  public func delete(envID: EnvironmentID? = nil, networkID: String) async throws
    -> MessageResponse {
    try await rest.delete(rest.environmentPath(envID, "networks/\(networkID)"))
  }

  /// Prune unused networks.
  public func prune(envID: EnvironmentID? = nil) async throws -> NetworkPruneReport {
    try await rest.post(rest.environmentPath(envID, "networks/prune"), body: EmptyBody?.none)
  }
}
