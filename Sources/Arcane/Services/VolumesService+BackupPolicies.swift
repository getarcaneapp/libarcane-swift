import Foundation

extension VolumesService {
  public func backupPolicies(envID: EnvironmentID? = nil, name: String) async throws -> VolumeBackupPolicyCollection {
    try await rest.get(rest.environmentPath(envID, "volumes/\(name)/backup-policy"))
  }

  public func updateBackupPolicies(envID: EnvironmentID? = nil, name: String, request: UpdateVolumeBackupPolicies) async throws -> VolumeBackupPolicyCollection {
    try await rest.put(rest.environmentPath(envID, "volumes/\(name)/backup-policy"), body: request)
  }

  public func listBackupsWithWarnings(envID: EnvironmentID? = nil, name: String, query: SearchPaginationSort = .init()) async throws -> VolumeBackupListPage {
    var items = query.nonPaginationQueryItems
    items.append(URLQueryItem(name: "start", value: String(query.start ?? 0)))
    items.append(URLQueryItem(name: "limit", value: String(query.limit ?? 20)))
    let data = try await rest.transport.rawRequest(rest.environmentPath(envID, "volumes/\(name)/backups"), query: items, body: EmptyBody?.none)
    do { return try rest.transport.decoder.decode(VolumeBackupListPage.self, from: data) }
    catch { throw ArcaneError.decoding(String(describing: error)) }
  }

  public func browseBackupFiles(envID: EnvironmentID? = nil, backupID: String, path: String = "", search: String = "", start: Int = 0, limit: Int = 20) async throws -> PaginatedResponse<BackupFileEntry> {
    try await rest.paginated(rest.environmentPath(envID, "volumes/backups/\(backupID)/files/browse"), start: start, limit: limit, query: [URLQueryItem(name: "path", value: path), URLQueryItem(name: "search", value: search)])
  }

  public func restoreBackupFiles(envID: EnvironmentID? = nil, name: String, backupID: String, selection: RestoreBackupFilesRequest) async throws -> MessageResponse {
    try await rest.post(rest.environmentPath(envID, "volumes/\(name)/backups/\(backupID)/restore-files"), body: selection)
  }

  public func uploadBackupToS3(envID: EnvironmentID? = nil, backupID: String, s3DestinationID: String) async throws -> BackupEntry {
    try await rest.post(rest.environmentPath(envID, "volumes/backups/\(backupID)/upload"), body: UploadVolumeBackupRequest(s3DestinationId: s3DestinationID))
  }

  /// Consumes a complete volume-backup upload session and restores the archive into the volume.
  public func uploadAndRestoreBackup(envID: EnvironmentID? = nil, name: String, uploadID: String) async throws -> MessageResponse {
    try await rest.post(rest.environmentPath(envID, "volumes/\(name)/backups/upload"), body: ["uploadId": uploadID])
  }
    /// Legacy multipart archive import for v1 servers. The response is a restore message, not a backup record.
    public func uploadAndRestoreBackup(envID: EnvironmentID? = nil, name: String, fileURL: URL) async throws -> MessageResponse {
        try await rest.transport.multipartUpload(rest.environmentPath(envID, "volumes/\(name)/backups/upload"),
            files: [MultipartFile(fieldName: "backup", filename: fileURL.lastPathComponent, fileURL: fileURL)])
    }
}
