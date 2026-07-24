import Foundation

/// ProjectsService exposes Docker Compose project management endpoints
/// registered under ``/environments/{id}/projects``.
///
/// The HTTP-streaming endpoints (``deploy``, ``redeploy``, ``build``,
/// ``pullImages``) issue the request and block until the operation's terminal
/// frame. Their corresponding stream methods expose progress line-by-line.
public struct ProjectsService: Sendable {
  private let rest: RESTService

  init(rest: RESTService) {
    self.rest = rest
  }

  // MARK: - Listing

  /// Paginated list of projects on the environment.
  public func list(
    envID: EnvironmentID? = nil,
    query: SearchPaginationSort = .init(),
    status: String? = nil,
    updates: String? = nil,
    archived: String? = nil
  ) async throws -> PaginatedResponse<ProjectDetails> {
    var items = query.nonPaginationQueryItems
    if let status {
      items.append(URLQueryItem(name: "status", value: status))
    }
    if let updates {
      items.append(URLQueryItem(name: "updates", value: updates))
    }
    if let archived {
      items.append(URLQueryItem(name: "archived", value: archived))
    }
    return try await rest.paginated(
      rest.environmentPath(envID, "projects"),
      start: query.start ?? 0,
      limit: query.limit ?? 20,
      query: items
    )
  }

  /// Aggregate counts of projects by status.
  public func statusCounts(envID: EnvironmentID? = nil) async throws -> ProjectStatusCounts {
    try await rest.get(rest.environmentPath(envID, "projects/counts"))
  }

  // MARK: - Single project read

  /// Get a single project by ID (no extra detail flags).
  public func get(envID: EnvironmentID? = nil, projectID: String) async throws -> ProjectDetails {
    try await rest.get(rest.environmentPath(envID, "projects/\(projectID)"))
  }

  /// Get the project compose details (compose content, includes, configs).
  public func compose(envID: EnvironmentID? = nil, projectID: String) async throws -> ProjectDetails
  {
    try await rest.get(rest.environmentPath(envID, "projects/\(projectID)/compose"))
  }

  /// Get the project's on-disk directory files.
  public func files(envID: EnvironmentID? = nil, projectID: String) async throws -> ProjectDetails {
    try await rest.get(rest.environmentPath(envID, "projects/\(projectID)/files"))
  }

  /// Get the project's runtime service state.
  public func runtime(envID: EnvironmentID? = nil, projectID: String) async throws -> ProjectDetails
  {
    try await rest.get(rest.environmentPath(envID, "projects/\(projectID)/runtime"))
  }

  /// Get the project's image update summary.
  public func updates(envID: EnvironmentID? = nil, projectID: String) async throws -> ProjectDetails
  {
    try await rest.get(rest.environmentPath(envID, "projects/\(projectID)/updates"))
  }

  /// Get the contents of a single project-related file by relative path.
  public func file(
    envID: EnvironmentID? = nil,
    projectID: String,
    relativePath: String
  ) async throws -> IncludeFile {
    try await rest.get(
      rest.environmentPath(envID, "projects/\(projectID)/file"),
      query: [URLQueryItem(name: "relativePath", value: relativePath)]
    )
  }

  // MARK: - Mutations

  /// Create a new Docker Compose project.
  public func create(
    envID: EnvironmentID? = nil,
    request: CreateProject
  ) async throws -> ProjectCreateResponse {
    try await rest.post(rest.environmentPath(envID, "projects"), body: request)
  }

  /// Update a project's name and/or compose/env content.
  public func update(
    envID: EnvironmentID? = nil,
    projectID: String,
    request: UpdateProject
  ) async throws -> ProjectDetails {
    try await rest.put(rest.environmentPath(envID, "projects/\(projectID)"), body: request)
  }

  /// Update a single include file inside a project.
  public func updateInclude(
    envID: EnvironmentID? = nil,
    projectID: String,
    request: UpdateIncludeFile
  ) async throws -> ProjectDetails {
    try await rest.put(
      rest.environmentPath(envID, "projects/\(projectID)/includes"),
      body: request
    )
  }

  // MARK: - Lifecycle

  /// Deploy a project (docker compose up).
  ///
  /// The server streams NDJSON progress; this call resolves only when the
  /// deploy is fully complete. Use ``deployStream`` for live progress.
  public func deploy(
    envID: EnvironmentID? = nil,
    projectID: String,
    options: DeployOptions? = nil
  ) async throws {
    let stream = try deployStream(envID: envID, projectID: projectID, options: options)
    for try await _ in stream {}
  }

  /// Bring down a project (docker compose down).
  @discardableResult
  public func down(envID: EnvironmentID? = nil, projectID: String) async throws
    -> MessageResponse {
    try await rest.post(
      rest.environmentPath(envID, "projects/\(projectID)/down"),
      body: EmptyBody?.none
    )
  }

  /// Redeploy a project (down + up).
  public func redeploy(envID: EnvironmentID? = nil, projectID: String) async throws {
    for try await _ in redeployStream(envID: envID, projectID: projectID) {}
  }

  /// Restart all containers in a project.
  @discardableResult
  public func restart(envID: EnvironmentID? = nil, projectID: String) async throws
    -> MessageResponse {
    try await rest.post(
      rest.environmentPath(envID, "projects/\(projectID)/restart"),
      body: EmptyBody?.none
    )
  }

  /// Destroy a project, optionally removing files and/or volumes.
  ///
  /// The destroy options are passed as URL query parameters since the
  /// shared ``RESTService`` DELETE helpers do not forward a request body.
  @discardableResult
  public func destroy(
    envID: EnvironmentID? = nil,
    projectID: String,
    options: DestroyProject? = nil
  ) async throws -> MessageResponse {
    var items: [URLQueryItem] = []
    if let options {
      if let removeFiles = options.removeFiles {
        items.append(URLQueryItem(name: "removeFiles", value: removeFiles ? "true" : "false"))
      }
      if let removeVolumes = options.removeVolumes {
        items.append(URLQueryItem(name: "removeVolumes", value: removeVolumes ? "true" : "false"))
      }
    }
    return try await rest.delete(
      rest.environmentPath(envID, "projects/\(projectID)/destroy"),
      query: items
    )
  }

  /// Archive a project (project must be stopped).
  public func archive(envID: EnvironmentID? = nil, projectID: String) async throws {
    try await rest.postVoid(
      rest.environmentPath(envID, "projects/\(projectID)/archive"),
      body: EmptyBody?.none
    )
  }

  /// Unarchive a project.
  public func unarchive(envID: EnvironmentID? = nil, projectID: String) async throws {
    try await rest.postVoid(
      rest.environmentPath(envID, "projects/\(projectID)/unarchive"),
      body: EmptyBody?.none
    )
  }

  /// Pull all images for a project. The server streams progress as NDJSON;
  /// the call resolves once the pull is complete. Use ``pullImagesStream``
  /// for live progress.
  public func pullImages(
    envID: EnvironmentID? = nil,
    projectID: String,
    request: ImagePullRequest? = nil
  ) async throws {
    let stream = try pullImagesStream(envID: envID, projectID: projectID, request: request)
    for try await _ in stream {}
  }

  /// Build compose services that declare a ``build`` directive. The server
  /// streams build progress as NDJSON; this call resolves once the build is
  /// complete. Use ``buildStream`` for live progress.
  public func build(
    envID: EnvironmentID? = nil,
    projectID: String,
    request: BuildProjectRequest? = nil
  ) async throws {
    let stream = try buildStream(envID: envID, projectID: projectID, request: request)
    for try await _ in stream {}
  }

  // MARK: - NDJSON progress streams

  /// Deploy a project and stream NDJSON progress events.
  public func deployStream(
    envID: EnvironmentID? = nil,
    projectID: String,
    options: DeployOptions? = nil
  ) throws -> NDJSONStream<OperationStreamEvent> {
    let body = try encodeOrNil(options)
    return NDJSONStream(
      transport: rest.transport,
      path: rest.environmentPath(envID, "projects/\(projectID)/up"),
      method: "POST",
      body: body,
      terminalAction: OperationStreamEvent.terminalAction
    )
  }

  /// Redeploy a project and stream NDJSON progress events.
  public func redeployStream(
    envID: EnvironmentID? = nil,
    projectID: String
  ) -> NDJSONStream<OperationStreamEvent> {
    NDJSONStream(
      transport: rest.transport,
      path: rest.environmentPath(envID, "projects/\(projectID)/redeploy"),
      method: "POST",
      body: nil,
      terminalAction: OperationStreamEvent.terminalAction
    )
  }

  /// Pull a project's images and stream NDJSON progress events.
  public func pullImagesStream(
    envID: EnvironmentID? = nil,
    projectID: String,
    request: ImagePullRequest? = nil
  ) throws -> NDJSONStream<OperationStreamEvent> {
    let body = try encodeOrNil(request)
    return NDJSONStream(
      transport: rest.transport,
      path: rest.environmentPath(envID, "projects/\(projectID)/pull"),
      method: "POST",
      body: body,
      terminalAction: OperationStreamEvent.terminalAction
    )
  }

  /// Build a project's images and stream NDJSON progress events.
  public func buildStream(
    envID: EnvironmentID? = nil,
    projectID: String,
    request: BuildProjectRequest? = nil
  ) throws -> NDJSONStream<OperationStreamEvent> {
    let body = try encodeOrNil(request)
    return NDJSONStream(
      transport: rest.transport,
      path: rest.environmentPath(envID, "projects/\(projectID)/build"),
      method: "POST",
      body: body,
      terminalAction: OperationStreamEvent.terminalAction
    )
  }

  private func encodeOrNil<T: Encodable>(_ value: T?) throws -> Data? {
    guard let value else { return nil }
    return try ArcaneJSON.makeEncoder().encode(value)
  }

  // MARK: - Streaming

  /// Stream project logs over WebSocket.
  public func logs(
    envID: EnvironmentID? = nil,
    projectID: String,
    follow: Bool = true,
    tail: String = "200",
    since: String? = nil,
    timestamps: Bool = false
  ) -> LogStream {
    LogStream(
      transport: rest.transport,
      path: rest.environmentPath(envID, "ws/projects/\(projectID)/logs"),
      query: LogStream.query(follow: follow, tail: tail, since: since, timestamps: timestamps)
    )
  }
}
