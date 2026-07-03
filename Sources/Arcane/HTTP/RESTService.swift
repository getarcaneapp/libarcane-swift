import Foundation

public struct RESTService: Sendable {
  public let transport: ArcaneURLSessionTransport
  public let defaultEnvironmentID: EnvironmentID

  public func get<T: Decodable & Sendable>(_ path: String, query: [URLQueryItem] = []) async throws
    -> T
  {
    try await transport.request(path, query: query)
  }

  public func post<T: Decodable & Sendable, Body: Encodable & Sendable>(
    _ path: String,
    body: Body? = nil,
    query: [URLQueryItem] = []
  ) async throws -> T {
    try await transport.request(path, method: "POST", query: query, body: body)
  }

  public func put<T: Decodable & Sendable, Body: Encodable & Sendable>(
    _ path: String,
    body: Body? = nil,
    query: [URLQueryItem] = []
  ) async throws -> T {
    try await transport.request(path, method: "PUT", query: query, body: body)
  }

  public func patch<T: Decodable & Sendable, Body: Encodable & Sendable>(
    _ path: String,
    body: Body? = nil,
    query: [URLQueryItem] = []
  ) async throws -> T {
    try await transport.request(path, method: "PATCH", query: query, body: body)
  }

  public func delete<T: Decodable & Sendable>(_ path: String, query: [URLQueryItem] = [])
    async throws -> T
  {
    try await transport.request(path, method: "DELETE", query: query)
  }

  public func deleteVoid(_ path: String, query: [URLQueryItem] = []) async throws {
    let _: MessageResponse = try await transport.request(path, method: "DELETE", query: query)
  }

  public func postVoid<Body: Encodable & Sendable>(
    _ path: String, body: Body? = nil, query: [URLQueryItem] = []
  ) async throws {
    let _: MessageResponse = try await transport.request(
      path, method: "POST", query: query, body: body)
  }

  public func putVoid<Body: Encodable & Sendable>(
    _ path: String, body: Body? = nil, query: [URLQueryItem] = []
  ) async throws {
    let _: MessageResponse = try await transport.request(
      path, method: "PUT", query: query, body: body)
  }

  public func paginated<T: Decodable & Sendable>(
    _ path: String,
    start: Int,
    limit: Int,
    query: [URLQueryItem] = []
  ) async throws -> PaginatedResponse<T> {
    try await transport.paginated(path, start: start, limit: limit, query: query)
  }

  public func environmentPath(_ envID: EnvironmentID?, _ suffix: String) -> String {
    "environments/\((envID ?? defaultEnvironmentID).rawValue)/\(suffix.trimmingCharacters(in: CharacterSet(charactersIn: "/")))"
  }
}

public struct AnyDecodable: Decodable, Sendable {
  public let value: JSONValue

  public init(from decoder: Decoder) throws {
    self.value = try JSONValue(from: decoder)
  }
}

extension JSONValue {
  public var doubleValue: Double? {
    if case .number(let value) = self { return value }
    return nil
  }

  public var intValue: Int? {
    if case .number(let value) = self { return Int(value) }
    return nil
  }

  public var int64Value: Int64? {
    if case .number(let value) = self { return Int64(value) }
    return nil
  }

  public var stringValue: String? {
    if case .string(let value) = self { return value }
    return nil
  }

  public var boolValue: Bool? {
    if case .bool(let value) = self { return value }
    return nil
  }
}
