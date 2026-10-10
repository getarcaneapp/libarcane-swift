import Foundation

extension SwarmService {
  // MARK: - Nodes

  /// Lists swarm nodes.
  public func listNodes(
    envID: EnvironmentID? = nil,
    search: String? = nil,
    sort: String? = nil,
    order: SortOrder? = nil,
    start: Int = 0,
    limit: Int = 20
  ) async throws -> PaginatedResponse<SwarmNode> {
    try await rest.transport.paginated(
      rest.environmentPath(envID, "swarm/nodes"),
      start: start,
      limit: limit,
      query: Self.startLimitQuery(
        search: search,
        sort: sort,
        order: order,
        start: start,
        limit: limit
      )
    )
  }

  /// Returns a single swarm node.
  public func node(_ nodeId: String, envID: EnvironmentID? = nil) async throws -> SwarmNode {
    try await rest.get(rest.environmentPath(envID, "swarm/nodes/\(nodeId)"))
  }

  /// Returns the node-agent deployment snippets for a swarm node.
  public func nodeAgentDeployment(
    _ nodeId: String,
    rotate: Bool = false,
    envID: EnvironmentID? = nil
  ) async throws -> SwarmNodeAgentDeployment {
    try await rest.post(
      rest.environmentPath(envID, "swarm/nodes/\(nodeId)/agent/deployment"),
      body: SwarmNodeAgentDeploymentRequest(rotate: rotate)
    )
  }

  /// Reconciles visible Arcane environment bindings for every node in a swarm.
  public func reconcileNodeAgents(
    envID: EnvironmentID? = nil,
    options: ArcaneRequestOptions? = nil
  ) async throws -> SwarmNodeAgentReconcileResponse {
    try await rest.post(
      rest.environmentPath(envID, "swarm/nodes/agents/reconcile"),
      body: EmptyBody(),
      options: options
    )
  }

  /// Attaches an existing Arcane environment to a swarm node.
  public func bindNodeAgent(
    _ nodeId: String,
    request: SwarmNodeAgentBindingRequest,
    envID: EnvironmentID? = nil,
    options: ArcaneRequestOptions? = nil
  ) async throws -> SwarmNode {
    try await rest.put(
      rest.environmentPath(envID, "swarm/nodes/\(nodeId)/agent/binding"),
      body: request,
      options: options
    )
  }

  /// Detaches the visible environment currently bound to a swarm node.
  public func detachNodeAgent(
    _ nodeId: String,
    envID: EnvironmentID? = nil,
    options: ArcaneRequestOptions? = nil
  ) async throws -> MessageResponse {
    try await rest.delete(
      rest.environmentPath(envID, "swarm/nodes/\(nodeId)/agent/binding"),
      options: options
    )
  }

  /// Removes a dedicated hidden node-agent registration.
  public func removeNodeAgentDeployment(
    _ nodeId: String,
    envID: EnvironmentID? = nil,
    options: ArcaneRequestOptions? = nil
  ) async throws -> MessageResponse {
    try await rest.delete(
      rest.environmentPath(envID, "swarm/nodes/\(nodeId)/agent/deployment"),
      options: options
    )
  }

  /// Updates a swarm node (labels / role / availability).
  public func updateNode(
    _ nodeId: String,
    _ request: SwarmNodeUpdateRequest,
    envID: EnvironmentID? = nil
  ) async throws {
    let _: MessageResponse = try await rest.patch(
      rest.environmentPath(envID, "swarm/nodes/\(nodeId)"),
      body: request
    )
  }

  /// Deletes a swarm node, optionally forcing removal.
  public func deleteNode(_ nodeId: String, force: Bool = false, envID: EnvironmentID? = nil)
    async throws {
    try await rest.deleteVoid(
      rest.environmentPath(envID, "swarm/nodes/\(nodeId)"),
      query: [URLQueryItem(name: "force", value: force ? "true" : "false")]
    )
  }

  /// Promotes a worker to manager.
  public func promoteNode(_ nodeId: String, envID: EnvironmentID? = nil) async throws {
    try await rest.postVoid(
      rest.environmentPath(envID, "swarm/nodes/\(nodeId)/promote"),
      body: Optional<EmptyBody>.none
    )
  }

  /// Demotes a manager to worker.
  public func demoteNode(_ nodeId: String, envID: EnvironmentID? = nil) async throws {
    try await rest.postVoid(
      rest.environmentPath(envID, "swarm/nodes/\(nodeId)/demote"),
      body: Optional<EmptyBody>.none
    )
  }

  /// Lists tasks running on a swarm node.
  public func nodeTasks(
    _ nodeId: String,
    envID: EnvironmentID? = nil,
    search: String? = nil,
    sort: String? = nil,
    order: SortOrder? = nil,
    start: Int = 0,
    limit: Int = 20
  ) async throws -> PaginatedResponse<SwarmTaskSummary> {
    try await rest.transport.paginated(
      rest.environmentPath(envID, "swarm/nodes/\(nodeId)/tasks"),
      start: start,
      limit: limit,
      query: Self.startLimitQuery(
        search: search,
        sort: sort,
        order: order,
        start: start,
        limit: limit
      )
    )
  }

  // MARK: - Tasks

  /// Lists every task in the swarm.
  public func listTasks(
    envID: EnvironmentID? = nil,
    search: String? = nil,
    sort: String? = nil,
    order: SortOrder? = nil,
    start: Int = 0,
    limit: Int = 20
  ) async throws -> PaginatedResponse<SwarmTaskSummary> {
    try await rest.transport.paginated(
      rest.environmentPath(envID, "swarm/tasks"),
      start: start,
      limit: limit,
      query: Self.startLimitQuery(
        search: search,
        sort: sort,
        order: order,
        start: start,
        limit: limit
      )
    )
  }

}
