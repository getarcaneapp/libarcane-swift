import Foundation

/// EdgeMTLSCertificate is the lightweight mTLS certificate status for an edge
/// environment surfaced in environment list/detail responses.
public struct EdgeMTLSCertificate: Codable, Hashable, Sendable {
    public var commonName: String?
    public var expiresAt: Date?
    public var daysRemaining: Int?
    public var expired: Bool
    public var expiringSoon: Bool

    public init(
        commonName: String? = nil,
        expiresAt: Date? = nil,
        daysRemaining: Int? = nil,
        expired: Bool = false,
        expiringSoon: Bool = false
    ) {
        self.commonName = commonName
        self.expiresAt = expiresAt
        self.daysRemaining = daysRemaining
        self.expired = expired
        self.expiringSoon = expiringSoon
    }
}

/// Environment represents one Docker environment (local or edge).
public struct Environment: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String?
    public var apiUrl: String
    public var status: String
    public var enabled: Bool
    public var isEdge: Bool
    public var lastSeen: Date?
    public var edgeTransport: String?
    /// Most recently used tunnel transport ("grpc" | "websocket"), persisted so
    /// it stays known while the tunnel is down or the agent is poll-only.
    public var lastEdgeTransport: String?
    public var edgeSecurityMode: String?
    public var edgeSessionId: String?
    public var edgeAgentInstance: String?
    public var edgeCapabilities: [String]?
    public var connected: Bool?
    public var connectedAt: Date?
    public var lastHeartbeat: Date?
    public var lastPollAt: Date?
    public var edgeMTLSCertificate: EdgeMTLSCertificate?
    public var apiKey: String?

    public init(
        id: String,
        name: String? = nil,
        apiUrl: String,
        status: String,
        enabled: Bool = true,
        isEdge: Bool = false,
        lastSeen: Date? = nil,
        edgeTransport: String? = nil,
        lastEdgeTransport: String? = nil,
        edgeSecurityMode: String? = nil,
        edgeSessionId: String? = nil,
        edgeAgentInstance: String? = nil,
        edgeCapabilities: [String]? = nil,
        connected: Bool? = nil,
        connectedAt: Date? = nil,
        lastHeartbeat: Date? = nil,
        lastPollAt: Date? = nil,
        edgeMTLSCertificate: EdgeMTLSCertificate? = nil,
        apiKey: String? = nil
    ) {
        self.id = id
        self.name = name
        self.apiUrl = apiUrl
        self.status = status
        self.enabled = enabled
        self.isEdge = isEdge
        self.lastSeen = lastSeen
        self.edgeTransport = edgeTransport
        self.lastEdgeTransport = lastEdgeTransport
        self.edgeSecurityMode = edgeSecurityMode
        self.edgeSessionId = edgeSessionId
        self.edgeAgentInstance = edgeAgentInstance
        self.edgeCapabilities = edgeCapabilities
        self.connected = connected
        self.connectedAt = connectedAt
        self.lastHeartbeat = lastHeartbeat
        self.lastPollAt = lastPollAt
        self.edgeMTLSCertificate = edgeMTLSCertificate
        self.apiKey = apiKey
    }
}

/// CreateEnvironment is the body for ``POST /environments``.
public struct CreateEnvironment: Codable, Hashable, Sendable {
    public var apiUrl: String
    public var name: String?
    public var enabled: Bool?
    public var accessToken: String?
    public var bootstrapToken: String?
    public var useApiKey: Bool?
    public var isEdge: Bool?

    public init(
        apiUrl: String,
        name: String? = nil,
        enabled: Bool? = nil,
        accessToken: String? = nil,
        bootstrapToken: String? = nil,
        useApiKey: Bool? = nil,
        isEdge: Bool? = nil
    ) {
        self.apiUrl = apiUrl
        self.name = name
        self.enabled = enabled
        self.accessToken = accessToken
        self.bootstrapToken = bootstrapToken
        self.useApiKey = useApiKey
        self.isEdge = isEdge
    }
}

/// UpdateEnvironment is the body for ``PUT /environments/{id}``.
public struct UpdateEnvironment: Codable, Hashable, Sendable {
    public var apiUrl: String?
    public var name: String?
    public var enabled: Bool?
    public var accessToken: String?
    public var bootstrapToken: String?
    public var regenerateApiKey: Bool?

    public init(
        apiUrl: String? = nil,
        name: String? = nil,
        enabled: Bool? = nil,
        accessToken: String? = nil,
        bootstrapToken: String? = nil,
        regenerateApiKey: Bool? = nil
    ) {
        self.apiUrl = apiUrl
        self.name = name
        self.enabled = enabled
        self.accessToken = accessToken
        self.bootstrapToken = bootstrapToken
        self.regenerateApiKey = regenerateApiKey
    }
}

/// EnvironmentTestResult is the response of the test-connection endpoint.
public struct EnvironmentTestResult: Codable, Hashable, Sendable {
    public var status: String
    public var message: String?

    public init(status: String, message: String? = nil) {
        self.status = status
        self.message = message
    }
}

/// TestConnectionRequest is the body for the test-connection endpoint.
public struct TestConnectionRequest: Codable, Hashable, Sendable {
    public var apiUrl: String?

    public init(apiUrl: String? = nil) {
        self.apiUrl = apiUrl
    }
}

/// AgentPairRequest is the body for the local agent pairing endpoint.
public struct AgentPairRequest: Codable, Hashable, Sendable {
    public var rotate: Bool?

    public init(rotate: Bool? = nil) {
        self.rotate = rotate
    }
}

/// AgentPairResponse is the response for the local agent pairing endpoint.
public struct AgentPairResponse: Codable, Hashable, Sendable {
    public var token: String

    public init(token: String) {
        self.token = token
    }
}

/// EnvironmentVersion is the response payload for the version endpoint.
public struct EnvironmentVersion: Codable, Hashable, Sendable {
    public var currentVersion: String
    public var currentTag: String?
    public var currentDigest: String?
    public var revision: String
    public var shortRevision: String
    public var goVersion: String
    public var enabledFeatures: [String]?
    public var buildTime: String?
    public var displayVersion: String
    public var isSemverVersion: Bool
    public var newestVersion: String?
    public var newestDigest: String?
    public var updateAvailable: Bool
    public var releaseUrl: String?
    public var releaseNotes: String?
    public var releasedAt: String?

    public init(
        currentVersion: String,
        currentTag: String? = nil,
        currentDigest: String? = nil,
        revision: String,
        shortRevision: String,
        goVersion: String,
        enabledFeatures: [String]? = nil,
        buildTime: String? = nil,
        displayVersion: String,
        isSemverVersion: Bool,
        newestVersion: String? = nil,
        newestDigest: String? = nil,
        updateAvailable: Bool,
        releaseUrl: String? = nil,
        releaseNotes: String? = nil,
        releasedAt: String? = nil
    ) {
        self.currentVersion = currentVersion
        self.currentTag = currentTag
        self.currentDigest = currentDigest
        self.revision = revision
        self.shortRevision = shortRevision
        self.goVersion = goVersion
        self.enabledFeatures = enabledFeatures
        self.buildTime = buildTime
        self.displayVersion = displayVersion
        self.isSemverVersion = isSemverVersion
        self.newestVersion = newestVersion
        self.newestDigest = newestDigest
        self.updateAvailable = updateAvailable
        self.releaseUrl = releaseUrl
        self.releaseNotes = releaseNotes
        self.releasedAt = releasedAt
    }
}
