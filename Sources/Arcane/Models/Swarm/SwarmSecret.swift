import Foundation

/// A swarm secret (named, write-only blob mountable into services).
public struct SwarmSecretSummary: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var version: JSONValue
    public var createdAt: Date
    public var updatedAt: Date
    public var spec: JSONValue

    public init(
        id: String,
        version: JSONValue,
        createdAt: Date,
        updatedAt: Date,
        spec: JSONValue
    ) {
        self.id = id
        self.version = version
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.spec = spec
    }
}

/// Body for creating a swarm secret (`spec` is the raw Docker SecretSpec).
public struct SwarmSecretCreateRequest: Codable, Hashable, Sendable {
    public var spec: JSONValue

    public init(spec: JSONValue) {
        self.spec = spec
    }
}

/// Body for updating a swarm secret.
public struct SwarmSecretUpdateRequest: Codable, Hashable, Sendable {
    public var version: UInt64?
    public var spec: JSONValue

    public init(version: UInt64? = nil, spec: JSONValue) {
        self.version = version
        self.spec = spec
    }
}
