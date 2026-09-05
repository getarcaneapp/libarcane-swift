import Foundation

/// VolumesService groups all volume, browse, and backup endpoints registered
/// under ``/environments/{id}/volumes``.
public struct VolumesService: Sendable {
  let rest: RESTService

  init(rest: RESTService) {
    self.rest = rest
  }

  // MARK: - Volumes

  /// Paginated list of Docker volumes for the environment.
  public func list(
    envID: EnvironmentID? = nil,
    query: SearchPaginationSort = .init(),
    inUse: Bool? = nil,
    includeInternal: Bool = false
  ) async throws -> PaginatedResponse<Volume> {
    var items = query.nonPaginationQueryItems
    if let inUse {
      items.append(URLQueryItem(name: "inUse", value: inUse ? "true" : "false"))
    }
    if includeInternal {
      items.append(URLQueryItem(name: "includeInternal", value: "true"))
    }
    return try await rest.paginated(
      rest.environmentPath(envID, "volumes"),
      start: query.start ?? 0,
      limit: query.limit ?? 20,
      query: items
    )
  }

  /// Get a single volume by name.
  public func inspect(envID: EnvironmentID? = nil, name: String) async throws -> Volume {
    try await rest.get(rest.environmentPath(envID, "volumes/\(name)"))
  }

  /// Create a new Docker volume.
  public func create(envID: EnvironmentID? = nil, request: CreateVolume) async throws -> Volume {
    try await rest.post(rest.environmentPath(envID, "volumes"), body: request)
  }

  /// Remove a volume, optionally forcing removal even if it is in use.
  @discardableResult
  public func remove(
    envID: EnvironmentID? = nil,
    name: String,
    force: Bool = false
  ) async throws -> MessageResponse {
    var items: [URLQueryItem] = []
    if force {
      items.append(URLQueryItem(name: "force", value: "true"))
    }
    return try await rest.delete(rest.environmentPath(envID, "volumes/\(name)"), query: items)
  }

  /// Prune unused volumes and return the prune report.
  public func prune(envID: EnvironmentID? = nil) async throws -> VolumePruneReport {
    try await rest.post(rest.environmentPath(envID, "volumes/prune"), body: EmptyBody?.none)
  }

  /// Get container usage information for a single volume.
  public func usage(envID: EnvironmentID? = nil, name: String) async throws -> VolumeUsage {
    try await rest.get(rest.environmentPath(envID, "volumes/\(name)/usage"))
  }

  /// Get aggregate usage counts (in use / unused / total).
  public func counts(envID: EnvironmentID? = nil, includeInternal: Bool = false) async throws
    -> VolumeUsageCounts
  {
    var items: [URLQueryItem] = []
    if includeInternal {
      items.append(URLQueryItem(name: "includeInternal", value: "true"))
    }
    return try await rest.get(rest.environmentPath(envID, "volumes/counts"), query: items)
  }

  /// Compute disk usage sizes for all volumes (slow).
  public func sizes(envID: EnvironmentID? = nil) async throws -> [VolumeSizeInfo] {
    try await rest.get(rest.environmentPath(envID, "volumes/sizes"))
  }

  // MARK: - Browse

  /// List directory entries inside a volume.
  public func browse(envID: EnvironmentID? = nil, name: String, path: String = "/") async throws
    -> [FileEntry]
  {
    try await rest.get(
      rest.environmentPath(envID, "volumes/\(name)/browse"),
      query: [URLQueryItem(name: "path", value: path)]
    )
  }

  /// Get a preview of a file in a volume.
  public func fileContent(
    envID: EnvironmentID? = nil,
    name: String,
    path: String,
    maxBytes: Int64 = 1_048_576
  ) async throws -> FileContent {
    try await rest.get(
      rest.environmentPath(envID, "volumes/\(name)/browse/content"),
      query: [
        URLQueryItem(name: "path", value: path),
        URLQueryItem(name: "maxBytes", value: "\(maxBytes)"),
      ]
    )
  }

  /// Create a new directory inside a volume.
  @discardableResult
  public func createDirectory(
    envID: EnvironmentID? = nil,
    name: String,
    path: String
  ) async throws -> MessageResponse {
    try await rest.post(
      rest.environmentPath(envID, "volumes/\(name)/browse/mkdir"),
      body: EmptyBody?.none,
      query: [URLQueryItem(name: "path", value: path)]
    )
  }

  /// Delete a file or directory inside a volume.
  @discardableResult
  public func deleteFile(
    envID: EnvironmentID? = nil,
    name: String,
    path: String
  ) async throws -> MessageResponse {
    try await rest.delete(
      rest.environmentPath(envID, "volumes/\(name)/browse"),
      query: [URLQueryItem(name: "path", value: path)]
    )
  }

  // MARK: - Backups

  /// Paginated list of backups for a volume.
  public func listBackups(
    envID: EnvironmentID? = nil,
    name: String,
    query: SearchPaginationSort = .init()
  ) async throws -> PaginatedResponse<BackupEntry> {
    try await rest.paginated(
      rest.environmentPath(envID, "volumes/\(name)/backups"),
      start: query.start ?? 0,
      limit: query.limit ?? 20,
      query: query.nonPaginationQueryItems
    )
  }

  /// Create a new backup of a volume.
  public func createBackup(envID: EnvironmentID? = nil, name: String, request: CreateVolumeBackupRequest = .init()) async throws -> BackupEntry {
    try await rest.post(
      rest.environmentPath(envID, "volumes/\(name)/backups"),
      body: request
    )
  }

  /// Restore an entire backup over a volume.
  @discardableResult
  public func restoreBackup(
    envID: EnvironmentID? = nil,
    name: String,
    backupID: String
  ) async throws -> MessageResponse {
    try await rest.post(
      rest.environmentPath(envID, "volumes/\(name)/backups/\(backupID)/restore"),
      body: EmptyBody?.none
    )
  }

  /// Restore selected files from a backup.
  @discardableResult
  public func restoreBackupFiles(
    envID: EnvironmentID? = nil,
    name: String,
    backupID: String,
    paths: [String]
  ) async throws -> MessageResponse {
    try await rest.post(
      rest.environmentPath(envID, "volumes/\(name)/backups/\(backupID)/restore-files"),
      body: RestoreBackupFilesRequest(paths: paths)
    )
  }

  /// Delete a backup.
  @discardableResult
  public func deleteBackup(envID: EnvironmentID? = nil, backupID: String) async throws
    -> MessageResponse {
    try await rest.delete(rest.environmentPath(envID, "volumes/backups/\(backupID)"))
  }

  /// Check whether a backup contains the given path.
  public func backupHasPath(
    envID: EnvironmentID? = nil,
    backupID: String,
    path: String
  ) async throws -> BackupHasPath {
    try await rest.get(
      rest.environmentPath(envID, "volumes/backups/\(backupID)/has-path"),
      query: [URLQueryItem(name: "path", value: path)]
    )
  }

  /// List the files contained inside a backup.
  public func listBackupFiles(envID: EnvironmentID? = nil, backupID: String) async throws
    -> [String]
  {
    try await rest.get(rest.environmentPath(envID, "volumes/backups/\(backupID)/files"))
  }

  // MARK: - Binary uploads & downloads

  /// Upload a file or directory into a volume at `path` (multipart upload).
  @discardableResult
  public func uploadFile(
    envID: EnvironmentID? = nil,
    name: String,
    path: String,
    fileURL: URL,
    filename: String? = nil
  ) async throws -> MessageResponse {
    let part = MultipartFile(
      fieldName: "file",
      filename: filename ?? fileURL.lastPathComponent,
      fileURL: fileURL
    )
    return try await rest.transport.multipartUpload(
      rest.environmentPath(envID, "volumes/\(name)/browse/upload"),
      query: [URLQueryItem(name: "path", value: path)],
      files: [part]
    )
  }

  /// Upload a backup tarball to a volume.
  @available(*, deprecated, message: "Use uploadAndRestoreBackup; this endpoint returns a restore message, not a backup record.")
  public func uploadBackup(
    envID: EnvironmentID? = nil,
    name: String,
    fileURL: URL,
    filename: String? = nil
  ) async throws -> BackupEntry {
    let part = MultipartFile(
      fieldName: "backup",
      filename: filename ?? fileURL.lastPathComponent,
      fileURL: fileURL
    )
    return try await rest.transport.multipartUpload(
      rest.environmentPath(envID, "volumes/\(name)/backups/upload"),
      files: [part]
    )
  }

  /// Download the raw bytes of a file inside a volume.
  @available(*, deprecated, message: "Use downloadFile(..., to:) for potentially large files.")
  public func downloadFile(envID: EnvironmentID? = nil, name: String, path: String) async throws
    -> Data
  {
    try await rest.transport.downloadRaw(
      rest.environmentPath(envID, "volumes/\(name)/browse/download"),
      query: [URLQueryItem(name: "path", value: path)]
    )
  }

  /// Download a file inside a volume directly to a destination URL.
  public func downloadFile(
    envID: EnvironmentID? = nil,
    name: String,
    path: String,
    to destinationURL: URL
  ) async throws {
    try await rest.transport.downloadRaw(
      rest.environmentPath(envID, "volumes/\(name)/browse/download"),
      query: [URLQueryItem(name: "path", value: path)],
      to: destinationURL
    )
  }

  /// Download a backup tarball as raw bytes.
  @available(*, deprecated, message: "Use downloadBackup(..., to:) for large backup archives.")
  public func downloadBackup(envID: EnvironmentID? = nil, backupID: String) async throws -> Data {
    try await rest.transport.downloadRaw(
      rest.environmentPath(envID, "volumes/backups/\(backupID)/download")
    )
  }

  /// Download a backup tarball directly to a destination URL.
  public func downloadBackup(
    envID: EnvironmentID? = nil,
    backupID: String,
    to destinationURL: URL
  ) async throws {
    try await rest.transport.downloadRaw(
      rest.environmentPath(envID, "volumes/backups/\(backupID)/download"),
      to: destinationURL
    )
  }
}
