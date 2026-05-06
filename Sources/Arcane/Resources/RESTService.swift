import Foundation

public struct RESTService: Sendable {
    let transport: ArcaneURLSessionTransport
    let defaultEnvironmentID: EnvironmentID

    init(transport: ArcaneURLSessionTransport, defaultEnvironmentID: EnvironmentID) {
        self.transport = transport
        self.defaultEnvironmentID = defaultEnvironmentID
    }

    public func get<T: Decodable & Sendable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        try await transport.request(path, query: query)
    }

    public func post<T: Decodable & Sendable, Body: Encodable & Sendable>(_ path: String, body: Body? = nil) async throws -> T {
        try await transport.request(path, method: "POST", body: body)
    }

    public func put<T: Decodable & Sendable, Body: Encodable & Sendable>(_ path: String, body: Body? = nil) async throws -> T {
        try await transport.request(path, method: "PUT", body: body)
    }

    public func delete<T: Decodable & Sendable>(_ path: String) async throws -> T {
        try await transport.request(path, method: "DELETE")
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
