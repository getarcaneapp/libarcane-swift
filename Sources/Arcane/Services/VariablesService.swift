import Foundation

/// Manager-level global-variable management.
public struct VariablesService: Sendable {
  private let rest: RESTService

  init(rest: RESTService) {
    self.rest = rest
  }

  public func list() async throws -> [GlobalVariable] {
    try await rest.get("variables")
  }

  public func create(
    _ request: CreateGlobalVariableRequest,
    options: ArcaneRequestOptions? = nil
  ) async throws -> GlobalVariableMutationResponse {
    try await rest.post("variables", body: request, options: options)
  }

  public func update(
    id: String,
    request: UpdateGlobalVariableRequest,
    options: ArcaneRequestOptions? = nil
  ) async throws -> GlobalVariableMutationResponse {
    try await rest.put("variables/\(id)", body: request, options: options)
  }

  public func delete(
    id: String,
    options: ArcaneRequestOptions? = nil
  ) async throws -> GlobalVariableMutationResponse {
    try await rest.delete("variables/\(id)", options: options)
  }

  public func sync(
    options: ArcaneRequestOptions? = nil
  ) async throws -> [EnvironmentSyncStatus] {
    try await rest.post("variables/sync", body: Optional<EmptyBody>.none, options: options)
  }

  public func syncStatus() async throws -> [EnvironmentSyncStatus] {
    try await rest.get("variables/sync-status")
  }
}
