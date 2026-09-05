import Foundation

/// Global, administrator-only system recovery and centralized volume backup operations.
public struct SystemBackupsService: Sendable {
  private let rest: RESTService
  init(rest: RESTService) { self.rest = rest }

  public func list(query: SearchPaginationSort = .init()) async throws -> PaginatedResponse<
    SystemBackupRun
  > {
    try await rest.paginated(
      "backups", start: query.start ?? 0, limit: query.limit ?? 20,
      query: query.nonPaginationQueryItems)
  }

  public func history(query: SearchPaginationSort = .init(), type: String? = nil) async throws
    -> PaginatedResponse<BackupHistoryEntry>
  {
    var items = query.nonPaginationQueryItems
    if let type { items.append(URLQueryItem(name: "type", value: type)) }
    return try await rest.paginated(
      "backups/history", start: query.start ?? 0, limit: query.limit ?? 20, query: items)
  }

  public func policies() async throws -> SystemBackupPolicyCollection {
    try await rest.requestPayload("backups/policies", method: "GET", body: EmptyBody?.none)
  }

  public func updatePolicies(_ request: UpdateSystemBackupPolicies) async throws
    -> SystemBackupPolicyCollection
  {
    try await rest.requestPayload("backups/policies", method: "PUT", body: request)
  }

  public func volumePolicies() async throws -> SystemVolumeBackupPolicyCollection {
    try await rest.requestPayload("backups/volumes/config", method: "GET", body: EmptyBody?.none)
  }

  public func updateVolumePolicies(_ request: UpdateSystemVolumeBackupPolicies) async throws
    -> SystemVolumeBackupPolicyCollection
  {
    try await rest.requestPayload("backups/volumes/config", method: "PUT", body: request)
  }

  public func volumeOptions() async throws -> [SystemVolumeBackupOption] {
    try await rest.requestPayload("backups/volumes/options", method: "GET", body: EmptyBody?.none)
  }

  /// Acceptance does not mean the backups have completed. Track the returned activity.
  public func runVolumeBackups(_ request: RunSystemVolumeBackupsRequest = .init()) async throws
    -> BackupRunAccepted
  {
    try await rest.requestPayload("backups/volumes/run", body: request)
  }

  public func generateRecoveryKey() async throws -> SystemBackupRecoveryKey {
    try await rest.requestPayload("backups/recovery-key/generate", body: EmptyBody?.none)
  }

  public func setRecoveryKey(_ request: SystemBackupRecoveryKey) async throws
    -> SystemBackupRecoveryKeyStatus
  {
    try await rest.requestPayload("backups/recovery-key", method: "PUT", body: request)
  }

  /// Returns the initial run, which may still be running.
  public func create(_ request: CreateSystemBackupRequest = .init()) async throws -> SystemBackupRun
  {
    try await rest.requestPayload("backups", body: request)
  }

  public func discover(_ request: DiscoverSystemBackupsRequest) async throws -> Int {
    try await rest.requestPayload("backups/discover", body: request)
  }

  public func restore(id: String, request: RestoreSystemBackupRequest) async throws
    -> MessageResponse
  {
    try await rest.requestPayload("backups/\(id)/restore", body: request)
  }

  public func browseFiles(
    id: String, recoveryKey: String, path: String = "", search: String = "", start: Int = 0,
    limit: Int = 20
  ) async throws -> PaginatedResponse<BackupFileEntry> {
    // This read uses POST so the recovery key never appears in the URL.
    try await rest.requestPayload(
      "backups/\(id)/files/browse", body: SystemBackupRecoveryKey(recoveryKey: recoveryKey),
      query: [
        URLQueryItem(name: "path", value: path), URLQueryItem(name: "search", value: search),
        URLQueryItem(name: "start", value: String(start)),
        URLQueryItem(name: "limit", value: String(limit)),
      ])
  }

  public func restoreFiles(id: String, request: RestoreSystemBackupFilesRequest) async throws
    -> MessageResponse
  {
    try await rest.requestPayload("backups/\(id)/restore-files", body: request)
  }

  public func upload(id: String, request: UploadSystemBackupRequest) async throws -> SystemBackupRun
  {
    try await rest.requestPayload("backups/\(id)/upload", body: request)
  }

  public func delete(id: String, recoveryKey: String? = nil) async throws -> MessageResponse {
    try await rest.requestPayload(
      "backups/\(id)", method: "DELETE", body: DeleteSystemBackupRequest(recoveryKey: recoveryKey))
  }

}
