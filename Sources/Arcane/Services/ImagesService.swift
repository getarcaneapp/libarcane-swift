import Foundation

public struct ImagesService: Sendable {
  private let rest: RESTService

  init(rest: RESTService) {
    self.rest = rest
  }

  // MARK: - Listing

  /// Paginated list of images in an environment.
  public func list(
    envID: EnvironmentID? = nil,
    query: SearchPaginationSort = .init(),
    inUse: String? = nil,
    updates: String? = nil
  ) async throws -> ImageListResponse {
    var items = query.nonPaginationQueryItems
    if let inUse { items.append(URLQueryItem(name: "inUse", value: inUse)) }
    if let updates { items.append(URLQueryItem(name: "updates", value: updates)) }
    let response: PaginatedResponse<ImageSummary> = try await rest.paginated(
      rest.environmentPath(envID, "images"),
      start: query.start ?? 0,
      limit: query.limit ?? 20,
      query: items
    )
    return ImageListResponse(
      success: response.success,
      data: response.data,
      pagination: response.pagination
    )
  }

  /// Aggregate counts of images (in use / unused / total / total size).
  public func usageCounts(envID: EnvironmentID? = nil) async throws -> ImageUsageCounts {
    try await rest.get(rest.environmentPath(envID, "images/counts"))
  }

  /// Inspect a single image by ID.
  public func inspect(envID: EnvironmentID? = nil, id: String) async throws -> ImageDetailSummary {
    try await rest.get(rest.environmentPath(envID, "images/\(id)"))
  }

  /// Docker layer history for an image ID or reference.
  public func history(envID: EnvironmentID? = nil, imageID: String) async throws
    -> [ImageHistoryItem]
  {
    try await rest.get(rest.environmentPath(envID, "images/\(imageID)/history"))
  }

  /// In-toto attestation statements attached to an image (provenance, SBOM, ...).
  ///
  /// - Parameters:
  ///   - platform: restrict to one platform (e.g. `linux/amd64`).
  ///   - predicateType: restrict to one predicate type URI.
  ///   - includeStatement: also return the full statement payloads.
  public func attestations(
    envID: EnvironmentID? = nil,
    id: String,
    platform: String? = nil,
    predicateType: String? = nil,
    includeStatement: Bool = false
  ) async throws -> ImageAttestationList {
    var items: [URLQueryItem] = []
    if let platform { items.append(URLQueryItem(name: "platform", value: platform)) }
    if let predicateType { items.append(URLQueryItem(name: "predicateType", value: predicateType)) }
    if includeStatement { items.append(URLQueryItem(name: "statement", value: "true")) }
    return try await rest.get(rest.environmentPath(envID, "images/\(id)/attestations"), query: items)
  }

  /// Remove an image, optionally forcing removal even if in use.
  public func remove(envID: EnvironmentID? = nil, id: String, force: Bool = false) async throws {
    let query = [URLQueryItem(name: "force", value: force ? "true" : "false")]
    try await rest.deleteVoid(rest.environmentPath(envID, "images/\(id)"), query: query)
  }

  // MARK: - Pull / Build (streaming endpoints)

  /// Initiate an image pull and drain its progress stream. Returns when the
  /// operation emits its terminal frame. Use ``pullStream`` for progress.
  public func pull(envID: EnvironmentID? = nil, options: ImagePullOptions) async throws {
    let stream = try pullStream(envID: envID, options: options)
    for try await _ in stream {}
  }

  /// Initiate an image pull and stream NDJSON progress frames as they arrive.
  public func pullStream(
    envID: EnvironmentID? = nil,
    options: ImagePullOptions
  ) throws -> NDJSONStream<OperationStreamEvent> {
    let body = try ArcaneJSON.makeEncoder().encode(options)
    return NDJSONStream(
      transport: rest.transport,
      path: rest.environmentPath(envID, "images/pull"),
      method: "POST",
      body: body,
      terminalAction: OperationStreamEvent.terminalAction
    )
  }

  /// Initiate an image build. Use `buildStream` for progress.
  public func build(envID: EnvironmentID? = nil, request: ImageBuildRequest) async throws {
    let stream = try buildStream(envID: envID, request: request)
    for try await _ in stream {}
  }

  /// Initiate an image build and stream NDJSON progress frames as they arrive.
  public func buildStream(
    envID: EnvironmentID? = nil,
    request: ImageBuildRequest
  ) throws -> NDJSONStream<OperationStreamEvent> {
    let body = try ArcaneJSON.makeEncoder().encode(request)
    return NDJSONStream(
      transport: rest.transport,
      path: rest.environmentPath(envID, "images/build"),
      method: "POST",
      body: body,
      terminalAction: OperationStreamEvent.terminalAction
    )
  }

  // MARK: - Upload

  /// Upload a Docker image tarball as a multipart file. Returns the result of
  /// loading the image into the local registry.
  public func upload(
    envID: EnvironmentID? = nil,
    fileURL: URL,
    filename: String? = nil,
    fieldName: String = "file"
  ) async throws -> ImageLoadResult {
    let name = filename ?? fileURL.lastPathComponent
    let part = MultipartFile(fieldName: fieldName, filename: name, fileURL: fileURL)
    return try await rest.transport.multipartUpload(
      rest.environmentPath(envID, "images/upload"),
      files: [part]
    )
  }

  // MARK: - Build history

  /// Paginated list of historical builds for this environment.
  public func listBuilds(
    envID: EnvironmentID? = nil,
    query: SearchPaginationSort = .init(),
    status: String? = nil,
    provider: String? = nil
  ) async throws -> PaginatedResponse<ImageBuildRecord> {
    var items = query.nonPaginationQueryItems
    if let status { items.append(URLQueryItem(name: "status", value: status)) }
    if let provider { items.append(URLQueryItem(name: "provider", value: provider)) }
    return try await rest.paginated(
      rest.environmentPath(envID, "images/builds"),
      start: query.start ?? 0,
      limit: query.limit ?? 20,
      query: items
    )
  }

  /// Inspect a single build history entry.
  public func getBuild(envID: EnvironmentID? = nil, buildId: String) async throws
    -> ImageBuildRecord
  {
    try await rest.get(rest.environmentPath(envID, "images/builds/\(buildId)"))
  }

  // MARK: - Prune

  /// Prune unused images. `mode` is typically "all" or "dangling".
  public func prune(
    envID: EnvironmentID? = nil,
    mode: String? = nil,
    until: String? = nil,
    dangling: Bool? = nil,
    filters: [String: [String]]? = nil
  ) async throws -> ImagePruneReport {
    struct Body: Encodable, Sendable {
      let mode: String?
      let until: String?
      let dangling: Bool?
      let filters: [String: [String]]?
    }
    let body = Body(mode: mode, until: until, dangling: dangling, filters: filters)
    return try await rest.post(rest.environmentPath(envID, "images/prune"), body: body)
  }

  // MARK: - Image updates

  /// Check whether an update is available for an image referenced by repo:tag.
  public func checkUpdateByRef(envID: EnvironmentID? = nil, imageRef: String) async throws
    -> ImageUpdateResponse
  {
    let query = [URLQueryItem(name: "imageRef", value: imageRef)]
    return try await rest.get(rest.environmentPath(envID, "image-updates/check"), query: query)
  }

  /// Check whether an update is available for an image by its Docker image ID (GET).
  public func checkUpdateByID(envID: EnvironmentID? = nil, imageId: String) async throws
    -> ImageUpdateResponse
  {
    try await rest.get(rest.environmentPath(envID, "image-updates/check/\(imageId)"))
  }

  /// Check whether an update is available for an image by its Docker image ID (POST).
  /// The POST variant exists for clients that prefer non-idempotent semantics.
  public func checkUpdateByIDPost(envID: EnvironmentID? = nil, imageId: String) async throws
    -> ImageUpdateResponse
  {
    try await rest.post(
      rest.environmentPath(envID, "image-updates/check/\(imageId)"), body: Optional<EmptyBody>.none)
  }

  /// Batch update check for a list of image references.
  public func checkBatchUpdates(
    envID: EnvironmentID? = nil,
    imageRefs: [String],
    credentials: [ContainerRegistryCredential]? = nil
  ) async throws -> ImageUpdateBatchResponse {
    let body = BatchImageUpdateRequest(imageRefs: imageRefs, credentials: credentials)
    return try await rest.post(rest.environmentPath(envID, "image-updates/check-batch"), body: body)
  }

  /// Check updates for all images in the environment.
  public func checkAllUpdates(
    envID: EnvironmentID? = nil,
    credentials: [ContainerRegistryCredential]? = nil
  ) async throws -> ImageUpdateBatchResponse {
    let body = CheckAllImagesRequest(credentials: credentials)
    return try await rest.post(rest.environmentPath(envID, "image-updates/check-all"), body: body)
  }

  /// Look up persisted update info for a set of image references.
  public func updateInfoByRefs(
    envID: EnvironmentID? = nil,
    imageRefs: [String]
  ) async throws -> [String: ImageUpdateInfo?] {
    let joined = imageRefs.joined(separator: ",")
    let query = [URLQueryItem(name: "imageRefs", value: joined)]
    return try await rest.get(rest.environmentPath(envID, "image-updates/by-refs"), query: query)
  }

  /// Aggregate summary of image updates for the environment.
  public func updateSummary(envID: EnvironmentID? = nil) async throws -> ImageUpdateSummary {
    try await rest.get(rest.environmentPath(envID, "image-updates/summary"))
  }
}
