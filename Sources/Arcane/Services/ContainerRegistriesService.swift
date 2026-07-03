import Foundation

/// ContainerRegistriesService manages container image registry configurations.
public struct ContainerRegistriesService: Sendable {
  private let rest: RESTService

  init(rest: RESTService) {
    self.rest = rest
  }

  /// List container registries with pagination.
  public func listPaginated(
    search: String? = nil,
    sort: String? = nil,
    order: SortOrder? = nil,
    start: Int = 0,
    limit: Int = 20
  ) async throws -> PaginatedResponse<ContainerRegistry> {
    var query: [URLQueryItem] = []
    if let search { query.append(URLQueryItem(name: "search", value: search)) }
    if let sort { query.append(URLQueryItem(name: "sort", value: sort)) }
    if let order { query.append(URLQueryItem(name: "order", value: order.rawValue)) }
    return try await rest.transport.paginated(
      "container-registries", start: start, limit: limit, query: query)
  }

  /// Get a container registry by ID.
  public func get(id: String) async throws -> ContainerRegistry {
    try await rest.get("container-registries/\(id)")
  }

  /// Create a new container registry.
  public func create(_ body: CreateContainerRegistry) async throws -> ContainerRegistry {
    try await rest.post("container-registries", body: body)
  }

  /// Update an existing container registry.
  public func update(id: String, body: UpdateContainerRegistry) async throws -> ContainerRegistry {
    try await rest.put("container-registries/\(id)", body: body)
  }

  /// Delete a container registry.
  public func delete(id: String) async throws {
    try await rest.deleteVoid("container-registries/\(id)")
  }

  /// Test connectivity and authentication for a container registry.
  public func test(id: String) async throws {
    try await rest.postVoid("container-registries/\(id)/test", body: EmptyBody?.none)
  }

  /// Sync container registries from a remote source (manager to agent).
  public func sync(_ body: ContainerRegistrySyncRequest) async throws {
    try await rest.postVoid("container-registries/sync", body: body)
  }

  /// Get pull-usage and rate-limit visibility for configured registries.
  public func pullUsage() async throws -> ContainerRegistryPullUsageResponse {
    try await rest.get("container-registries/pull-usage")
  }
}
