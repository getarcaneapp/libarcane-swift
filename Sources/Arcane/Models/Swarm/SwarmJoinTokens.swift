import Foundation

/// Body for `POST /environments/{id}/swarm/init`.
///
/// The Docker `spec` blob is preserved as raw JSON.
public struct SwarmInitRequest: Codable, Hashable, Sendable {
    public var listenAddr: String?
    public var advertiseAddr: String?
    public var dataPathAddr: String?
    public var dataPathPort: UInt32?
    public var forceNewCluster: Bool?
    public var spec: JSONValue
    public var autoLockManagers: Bool?
    public var availability: String?
    public var defaultAddrPool: [String]?
    public var subnetSize: UInt32?

    public init(
        listenAddr: String? = nil,
        advertiseAddr: String? = nil,
        dataPathAddr: String? = nil,
        dataPathPort: UInt32? = nil,
        forceNewCluster: Bool? = nil,
        spec: JSONValue,
        autoLockManagers: Bool? = nil,
        availability: String? = nil,
        defaultAddrPool: [String]? = nil,
        subnetSize: UInt32? = nil
    ) {
        self.listenAddr = listenAddr
        self.advertiseAddr = advertiseAddr
        self.dataPathAddr = dataPathAddr
        self.dataPathPort = dataPathPort
        self.forceNewCluster = forceNewCluster
        self.spec = spec
        self.autoLockManagers = autoLockManagers
        self.availability = availability
        self.defaultAddrPool = defaultAddrPool
        self.subnetSize = subnetSize
    }
}

/// Response from `POST /environments/{id}/swarm/init`.
public struct SwarmInitResponse: Codable, Hashable, Sendable {
    public var nodeId: String

    public init(nodeId: String) {
        self.nodeId = nodeId
    }
}

/// Body for `POST /environments/{id}/swarm/join`.
public struct SwarmJoinRequest: Codable, Hashable, Sendable {
    public var listenAddr: String?
    public var advertiseAddr: String?
    public var dataPathAddr: String?
    public var remoteAddrs: [String]
    public var joinToken: String
    public var availability: String?

    public init(
        listenAddr: String? = nil,
        advertiseAddr: String? = nil,
        dataPathAddr: String? = nil,
        remoteAddrs: [String],
        joinToken: String,
        availability: String? = nil
    ) {
        self.listenAddr = listenAddr
        self.advertiseAddr = advertiseAddr
        self.dataPathAddr = dataPathAddr
        self.remoteAddrs = remoteAddrs
        self.joinToken = joinToken
        self.availability = availability
    }
}

/// Body for `POST /environments/{id}/swarm/leave`.
public struct SwarmLeaveRequest: Codable, Hashable, Sendable {
    public var force: Bool?

    public init(force: Bool? = nil) {
        self.force = force
    }
}

/// Body for `POST /environments/{id}/swarm/unlock`.
public struct SwarmUnlockRequest: Codable, Hashable, Sendable {
    public var key: String

    public init(key: String) {
        self.key = key
    }
}

/// Response from `GET /environments/{id}/swarm/unlock-key`.
public struct SwarmUnlockKeyResponse: Codable, Hashable, Sendable {
    public var unlockKey: String

    public init(unlockKey: String) {
        self.unlockKey = unlockKey
    }
}

/// Worker / manager join tokens for the swarm.
public struct SwarmJoinTokens: Codable, Hashable, Sendable {
    public var worker: String
    public var manager: String

    public init(worker: String, manager: String) {
        self.worker = worker
        self.manager = manager
    }
}

/// Body for `POST /environments/{id}/swarm/join-tokens/rotate`.
public struct SwarmRotateJoinTokensRequest: Codable, Hashable, Sendable {
    public var rotateWorkerToken: Bool?
    public var rotateManagerToken: Bool?

    public init(rotateWorkerToken: Bool? = nil, rotateManagerToken: Bool? = nil) {
        self.rotateWorkerToken = rotateWorkerToken
        self.rotateManagerToken = rotateManagerToken
    }
}

/// Body for `PUT /environments/{id}/swarm/spec`.
public struct SwarmUpdateRequest: Codable, Hashable, Sendable {
    public var version: UInt64?
    public var spec: JSONValue
    public var rotateWorkerToken: Bool?
    public var rotateManagerToken: Bool?
    public var rotateManagerUnlockKey: Bool?

    public init(
        version: UInt64? = nil,
        spec: JSONValue,
        rotateWorkerToken: Bool? = nil,
        rotateManagerToken: Bool? = nil,
        rotateManagerUnlockKey: Bool? = nil
    ) {
        self.version = version
        self.spec = spec
        self.rotateWorkerToken = rotateWorkerToken
        self.rotateManagerToken = rotateManagerToken
        self.rotateManagerUnlockKey = rotateManagerUnlockKey
    }
}
