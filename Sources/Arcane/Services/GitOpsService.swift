import Foundation

/// GitOpsService manages Git repositories and GitOps sync configurations.
public struct GitOpsService: Sendable {
  private let rest: RESTService

  init(rest: RESTService) {
    self.rest = rest
  }

  // MARK: - Git repositories (top-level)

  /// List configured git repositories with pagination.
  public func listRepositoriesPaginated(
    search: String? = nil,
    sort: String? = nil,
    order: SortOrder? = nil,
    start: Int = 0,
    limit: Int = 20
  ) async throws -> PaginatedResponse<GitRepository> {
    var query: [URLQueryItem] = []
    if let search { query.append(URLQueryItem(name: "search", value: search)) }
    if let sort { query.append(URLQueryItem(name: "sort", value: sort)) }
    if let order { query.append(URLQueryItem(name: "order", value: order.rawValue)) }
    return try await rest.transport.paginated(
      "customize/git-repositories", start: start, limit: limit, query: query)
  }

  /// Get a git repository by ID.
  public func getRepository(id: String) async throws -> GitRepository {
    try await rest.get("customize/git-repositories/\(id)")
  }

  /// Create a new git repository configuration.
  public func createRepository(_ body: CreateGitRepository) async throws -> GitRepository {
    try await rest.post("customize/git-repositories", body: body)
  }

  /// Update an existing git repository.
  public func updateRepository(id: String, body: UpdateGitRepository) async throws -> GitRepository
  {
    try await rest.put("customize/git-repositories/\(id)", body: body)
  }

  /// Delete a git repository configuration.
  public func deleteRepository(id: String) async throws {
    try await rest.deleteVoid("customize/git-repositories/\(id)")
  }

  /// Test connectivity and authentication for a git repository.
  public func testRepository(id: String, branch: String? = nil) async throws {
    var query: [URLQueryItem] = []
    if let branch { query.append(URLQueryItem(name: "branch", value: branch)) }
    try await rest.postVoid(
      "customize/git-repositories/\(id)/test", body: EmptyBody?.none, query: query)
  }

  /// List branches available in a git repository.
  public func listBranches(id: String) async throws -> GitOpsBranchesResponse {
    try await rest.get("customize/git-repositories/\(id)/branches")
  }

  /// Browse files and directories in a git repository at the given branch.
  public func browseRepositoryFiles(id: String, branch: String, path: String? = nil) async throws
    -> GitOpsBrowseResponse
  {
    var query: [URLQueryItem] = [URLQueryItem(name: "branch", value: branch)]
    if let path { query.append(URLQueryItem(name: "path", value: path)) }
    return try await rest.get("customize/git-repositories/\(id)/files", query: query)
  }

  /// Sync git repositories from a manager to an agent instance.
  public func syncRepositories(_ body: GitRepositorySyncRequest) async throws {
    try await rest.postVoid("git-repositories/sync", body: body)
  }

  // MARK: - GitOps syncs (per environment)

  /// List GitOps syncs in the given environment with pagination.
  public func listSyncsPaginated(
    search: String? = nil,
    sort: String? = nil,
    order: SortOrder? = nil,
    start: Int = 0,
    limit: Int = 20,
    envID: EnvironmentID? = nil
  ) async throws -> PaginatedResponse<GitOpsSync> {
    var query: [URLQueryItem] = []
    if let search { query.append(URLQueryItem(name: "search", value: search)) }
    if let sort { query.append(URLQueryItem(name: "sort", value: sort)) }
    if let order { query.append(URLQueryItem(name: "order", value: order.rawValue)) }
    return try await rest.transport.paginated(
      rest.environmentPath(envID, "gitops-syncs"), start: start, limit: limit, query: query)
  }

  /// Create a new GitOps sync configuration.
  public func createSync(_ body: CreateGitOpsSync, envID: EnvironmentID? = nil) async throws
    -> GitOpsSync
  {
    try await rest.post(rest.environmentPath(envID, "gitops-syncs"), body: body)
  }

  /// Get a GitOps sync by ID.
  public func getSync(id: String, envID: EnvironmentID? = nil) async throws -> GitOpsSync {
    try await rest.get(rest.environmentPath(envID, "gitops-syncs/\(id)"))
  }

  /// Update an existing GitOps sync.
  public func updateSync(id: String, body: UpdateGitOpsSync, envID: EnvironmentID? = nil)
    async throws -> GitOpsSync
  {
    try await rest.put(rest.environmentPath(envID, "gitops-syncs/\(id)"), body: body)
  }

  /// Delete a GitOps sync.
  public func deleteSync(id: String, envID: EnvironmentID? = nil) async throws {
    try await rest.deleteVoid(rest.environmentPath(envID, "gitops-syncs/\(id)"))
  }

  /// Manually trigger a sync operation.
  public func performSync(id: String, envID: EnvironmentID? = nil) async throws -> GitOpsSyncResult
  {
    try await rest.post(
      rest.environmentPath(envID, "gitops-syncs/\(id)/sync"), body: EmptyBody?.none)
  }

  /// Get the current status of a GitOps sync.
  public func getSyncStatus(id: String, envID: EnvironmentID? = nil) async throws
    -> GitOpsSyncStatus
  {
    try await rest.get(rest.environmentPath(envID, "gitops-syncs/\(id)/status"))
  }

  /// Browse files in a synced repository.
  public func browseSyncFiles(id: String, path: String? = nil, envID: EnvironmentID? = nil)
    async throws -> GitOpsBrowseResponse
  {
    var query: [URLQueryItem] = []
    if let path { query.append(URLQueryItem(name: "path", value: path)) }
    return try await rest.get(rest.environmentPath(envID, "gitops-syncs/\(id)/files"), query: query)
  }

  /// Import multiple GitOps syncs from a JSON list.
  public func importSyncs(_ syncs: [ImportGitOpsSyncRequest], envID: EnvironmentID? = nil)
    async throws -> ImportGitOpsSyncResponse
  {
    try await rest.post(rest.environmentPath(envID, "gitops-syncs/import"), body: syncs)
  }
}
