import Foundation

public struct S3DestinationsService: Sendable {
  private let rest: RESTService
  init(rest: RESTService) { self.rest = rest }

  public func list(query: SearchPaginationSort = .init()) async throws -> PaginatedResponse<
    S3Destination
  > {
    try await rest.paginated(
      "backups/s3", start: query.start ?? 0, limit: query.limit ?? 20,
      query: query.nonPaginationQueryItems)
  }

  public func options() async throws -> [S3Destination] {
    try await rest.requestPayload("backups/s3/options", method: "GET", body: EmptyBody?.none)
  }

  public func get(id: String) async throws -> S3Destination {
    try await rest.requestPayload("backups/s3/\(id)", method: "GET", body: EmptyBody?.none)
  }

  public func create(_ request: CreateS3Destination) async throws -> S3Destination {
    try await rest.requestPayload("backups/s3", body: request)
  }

  /// An empty secretAccessKey preserves the stored secret.
  public func update(id: String, request: UpdateS3Destination) async throws -> S3Destination {
    try await rest.requestPayload("backups/s3/\(id)", method: "PUT", body: request)
  }

  public func delete(id: String) async throws -> MessageResponse {
    try await rest.delete("backups/s3/\(id)")
  }

  public func test(configuration: CreateS3Destination) async throws -> MessageResponse {
    try await rest.requestPayload("backups/s3/test", body: configuration)
  }

  public func test(id: String, configuration: UpdateS3Destination? = nil) async throws
    -> MessageResponse
  {
    try await rest.requestPayload("backups/s3/\(id)/test", body: configuration)
  }

  public func usage(id: String) async throws -> S3DestinationUsage {
    try await rest.requestPayload("backups/s3/\(id)/in-use", method: "GET", body: EmptyBody?.none)
  }
}
