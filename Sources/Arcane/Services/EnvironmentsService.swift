import Foundation

/// CreateEnvironmentResult is the response payload returned by ``create``.
/// It contains the created environment plus an optional one-time API key.
public struct CreateEnvironmentResult: Codable, Hashable, Sendable {
    public var environment: Environment
    public var apiKey: String?

    public init(environment: Environment, apiKey: String? = nil) {
        self.environment = environment
        self.apiKey = apiKey
    }

    private struct WireFormat: Decodable {
        var id: String
        var name: String?
        var apiUrl: String
        var status: String
        var enabled: Bool
        var isEdge: Bool
        var lastSeen: Date?
        var edgeTransport: String?
        var edgeSecurityMode: String?
        var edgeSessionId: String?
        var edgeAgentInstance: String?
        var edgeCapabilities: [String]?
        var connected: Bool?
        var connectedAt: Date?
        var lastHeartbeat: Date?
        var lastPollAt: Date?
        var edgeMTLSCertificate: EdgeMTLSCertificate?
        var apiKey: String?
    }

    public init(from decoder: Decoder) throws {
        let wire = try WireFormat(from: decoder)
        self.environment = Environment(
            id: wire.id,
            name: wire.name,
            apiUrl: wire.apiUrl,
            status: wire.status,
            enabled: wire.enabled,
            isEdge: wire.isEdge,
            lastSeen: wire.lastSeen,
            edgeTransport: wire.edgeTransport,
            edgeSecurityMode: wire.edgeSecurityMode,
            edgeSessionId: wire.edgeSessionId,
            edgeAgentInstance: wire.edgeAgentInstance,
            edgeCapabilities: wire.edgeCapabilities,
            connected: wire.connected,
            connectedAt: wire.connectedAt,
            lastHeartbeat: wire.lastHeartbeat,
            lastPollAt: wire.lastPollAt,
            edgeMTLSCertificate: wire.edgeMTLSCertificate,
            apiKey: wire.apiKey
        )
        self.apiKey = wire.apiKey
    }

    public func encode(to encoder: Encoder) throws {
        var env = environment
        env.apiKey = apiKey ?? environment.apiKey
        try env.encode(to: encoder)
    }
}

/// EnvironmentsService exposes the environment management endpoints registered
/// under ``/environments`` along with agent pairing, mTLS, and version helpers.
public struct EnvironmentsService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    // MARK: - CRUD

    /// Paginated list of environments.
    public func list(
        query: SearchPaginationSort = .init(),
        type: String? = nil
    ) async throws -> PaginatedResponse<Environment> {
        var items = query.queryItems
        if let type {
            items.append(URLQueryItem(name: "type", value: type))
        }
        return try await rest.paginated(
            "environments",
            start: query.start ?? 0,
            limit: query.limit ?? 20,
            query: items
        )
    }

    /// Get an environment by ID.
    public func get(id: EnvironmentID) async throws -> Environment {
        try await rest.get("environments/\(id.rawValue)")
    }

    /// Create a new environment. The response may include a one-time API key
    /// when ``CreateEnvironment/useApiKey`` is set to ``true``.
    public func create(request: CreateEnvironment) async throws -> CreateEnvironmentResult {
        try await rest.post("environments", body: request)
    }

    /// Update an environment.
    public func update(id: EnvironmentID, request: UpdateEnvironment) async throws -> Environment {
        try await rest.put("environments/\(id.rawValue)", body: request)
    }

    /// Delete an environment. The local environment cannot be deleted.
    public func delete(id: EnvironmentID) async throws {
        try await rest.deleteVoid("environments/\(id.rawValue)")
    }

    // MARK: - Status / Connectivity

    /// Test connectivity to an environment, optionally overriding the URL.
    public func testConnection(
        id: EnvironmentID,
        request: TestConnectionRequest? = nil
    ) async throws -> EnvironmentTestResult {
        try await rest.post("environments/\(id.rawValue)/test", body: request)
    }

    /// Update the heartbeat timestamp for an environment.
    public func updateHeartbeat(id: EnvironmentID) async throws {
        try await rest.postVoid(
            "environments/\(id.rawValue)/heartbeat",
            body: EmptyBody?.none
        )
    }

    /// Sync container registries and git repositories to an environment.
    public func sync(id: EnvironmentID) async throws {
        try await rest.postVoid(
            "environments/\(id.rawValue)/sync",
            body: EmptyBody?.none
        )
    }

    /// Get the version of a remote environment.
    public func version(id: EnvironmentID) async throws -> EnvironmentVersion {
        try await rest.get("environments/\(id.rawValue)/version")
    }

    // MARK: - Agent pairing

    /// Pair the manager with the local agent, optionally rotating the token.
    public func pairAgent(
        id: EnvironmentID = .localDocker,
        request: AgentPairRequest? = nil
    ) async throws -> AgentPairResponse {
        try await rest.post(
            "environments/\(id.rawValue)/agent/pair",
            body: request
        )
    }

    /// Complete the agent-to-manager pairing handshake by submitting the API
    /// key issued during environment creation. The agent sends this request
    /// with no Authorization header; the API key header is set by the caller.
    public func pairEnvironment() async throws {
        try await rest.postVoid("environments/pair", body: EmptyBody?.none)
    }

    // MARK: - Deployment snippets / mTLS

    /// Get the deployment snippets (docker run / compose / optional mTLS) for
    /// an environment.
    public func deploymentSnippets(id: EnvironmentID) async throws -> DeploymentSnippet {
        try await rest.get("environments/\(id.rawValue)/deployment")
    }

    /// Download the mTLS certificate bundle (zip) for an environment.
    public func downloadMTLSBundle(id: EnvironmentID) async throws -> Data {
        try await rest.transport.downloadRaw("environments/\(id.rawValue)/deployment/mtls/bundle")
    }

    /// Download a single mTLS file (PEM/key/etc.) for an environment.
    public func downloadMTLSFile(id: EnvironmentID, fileName: String) async throws -> Data {
        try await rest.transport.downloadRaw("environments/\(id.rawValue)/deployment/mtls/\(fileName)")
    }
}
