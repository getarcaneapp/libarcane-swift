import Foundation

public struct FederatedCredentialsService: Sendable {
  private let rest: RESTService

  init(rest: RESTService) { self.rest = rest }

  public func list(query: SearchPaginationSort = .init()) async throws -> PaginatedResponse<
    FederatedCredential
  > {
    try await rest.transport.paginated(
      "federated-credentials", start: query.start ?? 0,
      limit: query.limit ?? 20, query: query.nonPaginationQueryItems)
  }

  public func get(id: String) async throws -> FederatedCredential {
    try await rest.get("federated-credentials/\(id)")
  }

  public func create(_ body: CreateFederatedCredential) async throws -> FederatedCredential {
    try await rest.post("federated-credentials", body: body)
  }

  public func update(id: String, body: UpdateFederatedCredential) async throws
    -> FederatedCredential
  {
    try await rest.put("federated-credentials/\(id)", body: body)
  }

  public func delete(id: String) async throws {
    try await rest.deleteVoid("federated-credentials/\(id)")
  }
}
