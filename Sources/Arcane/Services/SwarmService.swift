import Foundation

/// Facade for the Docker Swarm endpoints under `/environments/{id}/swarm`.
///
/// This struct collides on name with the Docker concept of a "swarm service"
/// (a deployed service object), which is modeled as `SwarmServiceSummary` /
/// `SwarmServiceInspect` to keep things unambiguous.
public struct SwarmService: Sendable {
  let rest: RESTService

  // MARK: - Status / Info / Spec

  /// Returns whether swarm mode is enabled in this environment.
  public func status(envID: EnvironmentID? = nil) async throws -> SwarmRuntimeStatus {
    try await rest.get(rest.environmentPath(envID, "swarm/status"))
  }

  /// Returns the top-level swarm metadata.
  public func info(envID: EnvironmentID? = nil) async throws -> SwarmInfo {
    try await rest.get(rest.environmentPath(envID, "swarm/info"))
  }

  /// Updates the swarm-level spec.
  public func updateSpec(_ request: SwarmUpdateRequest, envID: EnvironmentID? = nil) async throws {
    try await rest.putVoid(rest.environmentPath(envID, "swarm/spec"), body: request)
  }

  // MARK: - Lifecycle

  /// Initializes a brand-new swarm cluster on this environment's Docker engine.
  public func initSwarm(_ request: SwarmInitRequest, envID: EnvironmentID? = nil) async throws
    -> SwarmInitResponse {
    try await rest.post(rest.environmentPath(envID, "swarm/init"), body: request)
  }

  /// Joins this environment's Docker engine to an existing swarm.
  public func join(_ request: SwarmJoinRequest, envID: EnvironmentID? = nil) async throws {
    try await rest.postVoid(rest.environmentPath(envID, "swarm/join"), body: request)
  }

  /// Returns enabled environments that can be joined to this manager's swarm.
  public func joinCandidates(envID: EnvironmentID? = nil) async throws
    -> [SwarmJoinCandidate] {
    try await rest.get(rest.environmentPath(envID, "swarm/join-candidates"))
  }

  /// Joins one or more Arcane environments without exposing swarm join tokens.
  public func joinEnvironments(
    _ request: SwarmJoinEnvironmentsRequest,
    envID: EnvironmentID? = nil,
    options: ArcaneRequestOptions? = nil
  ) async throws -> SwarmJoinEnvironmentsResponse {
    try await rest.post(
      rest.environmentPath(envID, "swarm/join-environments"),
      body: request,
      options: options
    )
  }

  /// Removes this environment's Docker engine from the swarm.
  public func leave(force: Bool = false, envID: EnvironmentID? = nil) async throws {
    try await rest.postVoid(
      rest.environmentPath(envID, "swarm/leave"),
      body: SwarmLeaveRequest(force: force)
    )
  }

  /// Unlocks the swarm using the provided unlock key.
  public func unlock(key: String, envID: EnvironmentID? = nil) async throws {
    try await rest.postVoid(
      rest.environmentPath(envID, "swarm/unlock"),
      body: SwarmUnlockRequest(key: key)
    )
  }

  /// Returns the swarm unlock key (requires admin).
  public func unlockKey(envID: EnvironmentID? = nil) async throws -> SwarmUnlockKeyResponse {
    try await rest.get(rest.environmentPath(envID, "swarm/unlock-key"))
  }

  /// Returns the local swarm node identity (used for cross-environment matching).
  /// This endpoint sits *outside* the environments tree.
  public func localNodeIdentity() async throws -> SwarmNodeIdentity {
    try await rest.get("swarm/node-identity")
  }

  // MARK: - Join tokens

  /// Returns the worker / manager join tokens for the swarm.
  public func joinTokens(envID: EnvironmentID? = nil) async throws -> SwarmJoinTokens {
    try await rest.get(rest.environmentPath(envID, "swarm/join-tokens"))
  }

  /// Rotates the swarm join tokens.
  public func rotateJoinTokens(_ request: SwarmRotateJoinTokensRequest, envID: EnvironmentID? = nil)
    async throws {
    try await rest.postVoid(rest.environmentPath(envID, "swarm/join-tokens/rotate"), body: request)
  }

  // MARK: - Services

  /// Lists swarm services with offset-based pagination.
  public func listServices(
    envID: EnvironmentID? = nil,
    search: String? = nil,
    sort: String? = nil,
    order: SortOrder? = nil,
    start: Int = 0,
    limit: Int = 20
  ) async throws -> PaginatedResponse<SwarmServiceSummary> {
    try await rest.transport.paginated(
      rest.environmentPath(envID, "swarm/services"),
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

  /// Inspects a single swarm service.
  public func service(_ serviceId: String, envID: EnvironmentID? = nil) async throws
    -> SwarmServiceInspect {
    try await rest.get(rest.environmentPath(envID, "swarm/services/\(serviceId)"))
  }

  /// Creates a new swarm service.
  public func createService(
    _ request: SwarmServiceCreateRequest,
    envID: EnvironmentID? = nil
  ) async throws -> SwarmServiceCreateResponse {
    try await rest.post(rest.environmentPath(envID, "swarm/services"), body: request)
  }

  /// Updates an existing swarm service.
  public func updateService(
    _ serviceId: String,
    _ request: SwarmServiceUpdateRequest,
    envID: EnvironmentID? = nil
  ) async throws -> SwarmServiceUpdateResponse {
    try await rest.put(rest.environmentPath(envID, "swarm/services/\(serviceId)"), body: request)
  }

  /// Deletes a swarm service.
  public func deleteService(_ serviceId: String, envID: EnvironmentID? = nil) async throws {
    try await rest.deleteVoid(rest.environmentPath(envID, "swarm/services/\(serviceId)"))
  }

  /// Lists the tasks belonging to a swarm service.
  public func serviceTasks(
    _ serviceId: String,
    envID: EnvironmentID? = nil,
    search: String? = nil,
    sort: String? = nil,
    order: SortOrder? = nil,
    start: Int = 0,
    limit: Int = 20
  ) async throws -> PaginatedResponse<SwarmTaskSummary> {
    try await rest.transport.paginated(
      rest.environmentPath(envID, "swarm/services/\(serviceId)/tasks"),
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

  /// Rolls a swarm service back to its previous spec.
  public func rollbackService(_ serviceId: String, envID: EnvironmentID? = nil) async throws
    -> SwarmServiceUpdateResponse {
    try await rest.post(
      rest.environmentPath(envID, "swarm/services/\(serviceId)/rollback"),
      body: Optional<EmptyBody>.none
    )
  }

  /// Scales a replicated swarm service.
  public func scaleService(
    _ serviceId: String,
    replicas: UInt64,
    envID: EnvironmentID? = nil
  ) async throws -> SwarmServiceUpdateResponse {
    try await rest.post(
      rest.environmentPath(envID, "swarm/services/\(serviceId)/scale"),
      body: SwarmServiceScaleRequest(replicas: replicas)
    )
  }

  // MARK: - Stacks

  /// Lists stacks deployed to the swarm.
  public func listStacks(
    envID: EnvironmentID? = nil,
    search: String? = nil,
    sort: String? = nil,
    order: SortOrder? = nil,
    start: Int = 0,
    limit: Int = 20
  ) async throws -> PaginatedResponse<SwarmStackSummary> {
    try await rest.transport.paginated(
      rest.environmentPath(envID, "swarm/stacks"),
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

  /// Deploys (creates or updates) a stack from a compose document.
  public func deployStack(_ request: SwarmStackDeployRequest, envID: EnvironmentID? = nil)
    async throws -> SwarmStackDeployResponse {
    try await rest.post(rest.environmentPath(envID, "swarm/stacks"), body: request)
  }

  /// Inspects a single stack by name.
  public func stack(_ name: String, envID: EnvironmentID? = nil) async throws -> SwarmStackInspect {
    try await rest.get(rest.environmentPath(envID, "swarm/stacks/\(name)"))
  }

  /// Returns the persisted compose source for a stack.
  public func stackSource(_ name: String, envID: EnvironmentID? = nil) async throws
    -> SwarmStackSource {
    try await rest.get(rest.environmentPath(envID, "swarm/stacks/\(name)/source"))
  }

  /// Updates the persisted compose source for a stack.
  public func updateStackSource(
    _ name: String,
    _ request: SwarmStackSourceUpdateRequest,
    envID: EnvironmentID? = nil
  ) async throws -> SwarmStackSource {
    try await rest.put(rest.environmentPath(envID, "swarm/stacks/\(name)/source"), body: request)
  }

  /// Removes a deployed stack.
  public func deleteStack(_ name: String, envID: EnvironmentID? = nil) async throws {
    try await rest.deleteVoid(rest.environmentPath(envID, "swarm/stacks/\(name)"))
  }

  /// Lists the services that belong to a stack.
  public func stackServices(
    _ name: String,
    envID: EnvironmentID? = nil,
    search: String? = nil,
    sort: String? = nil,
    order: SortOrder? = nil,
    start: Int = 0,
    limit: Int = 20
  ) async throws -> PaginatedResponse<SwarmServiceSummary> {
    try await rest.transport.paginated(
      rest.environmentPath(envID, "swarm/stacks/\(name)/services"),
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

  /// Lists the tasks that belong to a stack.
  public func stackTasks(
    _ name: String,
    envID: EnvironmentID? = nil,
    search: String? = nil,
    sort: String? = nil,
    order: SortOrder? = nil,
    start: Int = 0,
    limit: Int = 20
  ) async throws -> PaginatedResponse<SwarmTaskSummary> {
    try await rest.transport.paginated(
      rest.environmentPath(envID, "swarm/stacks/\(name)/tasks"),
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

  /// Renders / validates a compose document without deploying it.
  public func renderStackConfig(
    _ request: SwarmStackRenderConfigRequest,
    envID: EnvironmentID? = nil
  ) async throws -> SwarmStackRenderConfigResponse {
    try await rest.post(rest.environmentPath(envID, "swarm/stacks/config/render"), body: request)
  }

  // MARK: - Configs

  /// Lists swarm configs.
  public func listConfigs(envID: EnvironmentID? = nil) async throws -> [SwarmConfigSummary] {
    try await rest.get(rest.environmentPath(envID, "swarm/configs"))
  }

  /// Inspects a single swarm config.
  public func config(_ configId: String, envID: EnvironmentID? = nil) async throws
    -> SwarmConfigSummary {
    try await rest.get(rest.environmentPath(envID, "swarm/configs/\(configId)"))
  }

  /// Creates a new swarm config.
  public func createConfig(_ request: SwarmConfigCreateRequest, envID: EnvironmentID? = nil)
    async throws -> SwarmConfigSummary {
    try await rest.post(rest.environmentPath(envID, "swarm/configs"), body: request)
  }

  /// Updates a swarm config.
  public func updateConfig(
    _ configId: String,
    _ request: SwarmConfigUpdateRequest,
    envID: EnvironmentID? = nil
  ) async throws -> SwarmConfigSummary {
    try await rest.put(rest.environmentPath(envID, "swarm/configs/\(configId)"), body: request)
  }

  /// Deletes a swarm config.
  public func deleteConfig(_ configId: String, envID: EnvironmentID? = nil) async throws {
    try await rest.deleteVoid(rest.environmentPath(envID, "swarm/configs/\(configId)"))
  }

  // MARK: - Secrets

  /// Lists swarm secrets.
  public func listSecrets(envID: EnvironmentID? = nil) async throws -> [SwarmSecretSummary] {
    try await rest.get(rest.environmentPath(envID, "swarm/secrets"))
  }

  /// Inspects a single swarm secret.
  public func secret(_ secretId: String, envID: EnvironmentID? = nil) async throws
    -> SwarmSecretSummary {
    try await rest.get(rest.environmentPath(envID, "swarm/secrets/\(secretId)"))
  }

  /// Creates a new swarm secret.
  public func createSecret(_ request: SwarmSecretCreateRequest, envID: EnvironmentID? = nil)
    async throws -> SwarmSecretSummary {
    try await rest.post(rest.environmentPath(envID, "swarm/secrets"), body: request)
  }

  /// Updates a swarm secret.
  public func updateSecret(
    _ secretId: String,
    _ request: SwarmSecretUpdateRequest,
    envID: EnvironmentID? = nil
  ) async throws -> SwarmSecretSummary {
    try await rest.put(rest.environmentPath(envID, "swarm/secrets/\(secretId)"), body: request)
  }

  /// Deletes a swarm secret.
  public func deleteSecret(_ secretId: String, envID: EnvironmentID? = nil) async throws {
    try await rest.deleteVoid(rest.environmentPath(envID, "swarm/secrets/\(secretId)"))
  }

  // MARK: - WebSocket streams

  /// Streams logs for a swarm service over a WebSocket connection.
  public func serviceLogs(
    _ serviceId: String,
    envID: EnvironmentID? = nil,
    follow: Bool = true,
    tail: String = "100",
    since: String? = nil,
    timestamps: Bool = false
  ) -> LogStream {
    let env = (envID ?? rest.defaultEnvironmentID).rawValue
    var query: [URLQueryItem] = [
      URLQueryItem(name: "follow", value: follow ? "true" : "false"),
      URLQueryItem(name: "tail", value: tail),
      URLQueryItem(name: "timestamps", value: timestamps ? "true" : "false")
    ]
    if let since {
      query.append(URLQueryItem(name: "since", value: since))
    }
    return LogStream(
      transport: rest.transport,
      path: "environments/\(env)/ws/swarm/services/\(serviceId)/logs",
      query: query
    )
  }

  // MARK: - Helpers

  static func startLimitQuery(
    search: String?,
    sort: String?,
    order: SortOrder?,
    start: Int,
    limit: Int
  ) -> [URLQueryItem] {
    var items: [URLQueryItem] = []
    if let search { items.append(URLQueryItem(name: "search", value: search)) }
    if let sort { items.append(URLQueryItem(name: "sort", value: sort)) }
    if let order { items.append(URLQueryItem(name: "order", value: order.rawValue)) }
    return items
  }
}
