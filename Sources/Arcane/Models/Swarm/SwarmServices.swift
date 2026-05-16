import Foundation

/// A published port mapping for a swarm service endpoint.
public struct SwarmServicePort: Codable, Hashable, Sendable {
    public var protocolName: String
    public var targetPort: UInt32
    public var publishedPort: UInt32?
    public var publishMode: String?

    public init(
        protocolName: String,
        targetPort: UInt32,
        publishedPort: UInt32? = nil,
        publishMode: String? = nil
    ) {
        self.protocolName = protocolName
        self.targetPort = targetPort
        self.publishedPort = publishedPort
        self.publishMode = publishMode
    }

    private enum CodingKeys: String, CodingKey {
        case protocolName = "protocol"
        case targetPort
        case publishedPort
        case publishMode
    }
}

/// A mount configured on a swarm service task.
public struct SwarmServiceMount: Codable, Hashable, Sendable {
    public var type: String
    public var source: String?
    public var target: String
    public var readOnly: Bool?
    public var volumeDriver: String?
    public var volumeOptions: [String: String]?
    public var devicePath: String?

    public init(
        type: String,
        source: String? = nil,
        target: String,
        readOnly: Bool? = nil,
        volumeDriver: String? = nil,
        volumeOptions: [String: String]? = nil,
        devicePath: String? = nil
    ) {
        self.type = type
        self.source = source
        self.target = target
        self.readOnly = readOnly
        self.volumeDriver = volumeDriver
        self.volumeOptions = volumeOptions
        self.devicePath = devicePath
    }
}

/// Lightweight summary of a swarm service used in list views.
///
/// Named `SwarmServiceSummary` to avoid collision with the `SwarmService`
/// facade in `Services/SwarmService.swift`.
public struct SwarmServiceSummary: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var image: String
    public var mode: String
    public var replicas: UInt64
    public var runningReplicas: UInt64
    public var ports: [SwarmServicePort]
    public var createdAt: Date
    public var updatedAt: Date
    public var labels: [String: String]?
    public var stackName: String?
    public var nodes: [String]
    public var networks: [String]
    public var mounts: [SwarmServiceMount]

    public init(
        id: String,
        name: String,
        image: String,
        mode: String,
        replicas: UInt64,
        runningReplicas: UInt64,
        ports: [SwarmServicePort] = [],
        createdAt: Date,
        updatedAt: Date,
        labels: [String: String]? = nil,
        stackName: String? = nil,
        nodes: [String] = [],
        networks: [String] = [],
        mounts: [SwarmServiceMount] = []
    ) {
        self.id = id
        self.name = name
        self.image = image
        self.mode = mode
        self.replicas = replicas
        self.runningReplicas = runningReplicas
        self.ports = ports
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.labels = labels
        self.stackName = stackName
        self.nodes = nodes
        self.networks = networks
        self.mounts = mounts
    }
}

/// A single IPAM configuration entry for a service-attached network.
public struct SwarmServiceNetworkIPAMConfig: Codable, Hashable, Sendable {
    public var subnet: String?
    public var gateway: String?
    public var ipRange: String?

    public init(subnet: String? = nil, gateway: String? = nil, ipRange: String? = nil) {
        self.subnet = subnet
        self.gateway = gateway
        self.ipRange = ipRange
    }
}

/// Details about a config-only network referenced by `configFrom`.
public struct SwarmServiceNetworkConfigDetail: Codable, Hashable, Sendable {
    public var name: String
    public var driver: String
    public var scope: String
    public var enableIPv4: Bool
    public var enableIPv6: Bool
    public var options: [String: String]?
    public var ipv4Configs: [SwarmServiceNetworkIPAMConfig]?
    public var ipv6Configs: [SwarmServiceNetworkIPAMConfig]?

    public init(
        name: String,
        driver: String,
        scope: String,
        enableIPv4: Bool,
        enableIPv6: Bool,
        options: [String: String]? = nil,
        ipv4Configs: [SwarmServiceNetworkIPAMConfig]? = nil,
        ipv6Configs: [SwarmServiceNetworkIPAMConfig]? = nil
    ) {
        self.name = name
        self.driver = driver
        self.scope = scope
        self.enableIPv4 = enableIPv4
        self.enableIPv6 = enableIPv6
        self.options = options
        self.ipv4Configs = ipv4Configs
        self.ipv6Configs = ipv6Configs
    }
}

/// Enriched network info for a service's attached network.
public struct SwarmServiceNetworkDetail: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var driver: String
    public var scope: String
    public var internalNetwork: Bool
    public var attachable: Bool
    public var ingress: Bool
    public var enableIPv4: Bool
    public var enableIPv6: Bool
    public var configFrom: String?
    public var configOnly: Bool
    public var options: [String: String]?
    public var ipamConfigs: [SwarmServiceNetworkIPAMConfig]?
    public var configNetwork: SwarmServiceNetworkConfigDetail?

    public init(
        id: String,
        name: String,
        driver: String,
        scope: String,
        internalNetwork: Bool,
        attachable: Bool,
        ingress: Bool,
        enableIPv4: Bool,
        enableIPv6: Bool,
        configFrom: String? = nil,
        configOnly: Bool,
        options: [String: String]? = nil,
        ipamConfigs: [SwarmServiceNetworkIPAMConfig]? = nil,
        configNetwork: SwarmServiceNetworkConfigDetail? = nil
    ) {
        self.id = id
        self.name = name
        self.driver = driver
        self.scope = scope
        self.internalNetwork = internalNetwork
        self.attachable = attachable
        self.ingress = ingress
        self.enableIPv4 = enableIPv4
        self.enableIPv6 = enableIPv6
        self.configFrom = configFrom
        self.configOnly = configOnly
        self.options = options
        self.ipamConfigs = ipamConfigs
        self.configNetwork = configNetwork
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, driver, scope
        case internalNetwork = "internal"
        case attachable, ingress, enableIPv4, enableIPv6
        case configFrom, configOnly, options, ipamConfigs, configNetwork
    }
}

/// Full inspect payload for a swarm service. Docker SDK sub-blobs (spec,
/// endpoint, version, updateStatus) are preserved verbatim as JSON.
public struct SwarmServiceInspect: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var version: JSONValue
    public var createdAt: Date
    public var updatedAt: Date
    public var spec: JSONValue
    public var endpoint: JSONValue
    public var updateStatus: JSONValue?
    public var nodes: [String]?
    public var networkDetails: [String: SwarmServiceNetworkDetail]?
    public var mounts: [SwarmServiceMount]?

    public init(
        id: String,
        version: JSONValue,
        createdAt: Date,
        updatedAt: Date,
        spec: JSONValue,
        endpoint: JSONValue,
        updateStatus: JSONValue? = nil,
        nodes: [String]? = nil,
        networkDetails: [String: SwarmServiceNetworkDetail]? = nil,
        mounts: [SwarmServiceMount]? = nil
    ) {
        self.id = id
        self.version = version
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.spec = spec
        self.endpoint = endpoint
        self.updateStatus = updateStatus
        self.nodes = nodes
        self.networkDetails = networkDetails
        self.mounts = mounts
    }
}

/// Extra options used when creating a swarm service.
public struct SwarmServiceCreateOptions: Codable, Hashable, Sendable {
    public var encodedRegistryAuth: String?
    public var queryRegistry: Bool?

    public init(encodedRegistryAuth: String? = nil, queryRegistry: Bool? = nil) {
        self.encodedRegistryAuth = encodedRegistryAuth
        self.queryRegistry = queryRegistry
    }
}

/// Extra options used when updating a swarm service.
public struct SwarmServiceUpdateOptions: Codable, Hashable, Sendable {
    public var encodedRegistryAuth: String?
    public var registryAuthFrom: String?
    public var rollback: String?
    public var queryRegistry: Bool?

    public init(
        encodedRegistryAuth: String? = nil,
        registryAuthFrom: String? = nil,
        rollback: String? = nil,
        queryRegistry: Bool? = nil
    ) {
        self.encodedRegistryAuth = encodedRegistryAuth
        self.registryAuthFrom = registryAuthFrom
        self.rollback = rollback
        self.queryRegistry = queryRegistry
    }
}

/// Body for creating a swarm service. `spec` is the raw Docker ServiceSpec JSON.
public struct SwarmServiceCreateRequest: Codable, Hashable, Sendable {
    public var spec: JSONValue
    public var options: SwarmServiceCreateOptions?

    public init(spec: JSONValue, options: SwarmServiceCreateOptions? = nil) {
        self.spec = spec
        self.options = options
    }
}

/// Body for updating a swarm service.
public struct SwarmServiceUpdateRequest: Codable, Hashable, Sendable {
    public var version: UInt64
    public var spec: JSONValue
    public var options: SwarmServiceUpdateOptions?

    public init(version: UInt64, spec: JSONValue, options: SwarmServiceUpdateOptions? = nil) {
        self.version = version
        self.spec = spec
        self.options = options
    }
}

/// Response for swarm service create.
public struct SwarmServiceCreateResponse: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var warnings: [String]?

    public init(id: String, warnings: [String]? = nil) {
        self.id = id
        self.warnings = warnings
    }
}

/// Response for swarm service update / rollback / scale.
public struct SwarmServiceUpdateResponse: Codable, Hashable, Sendable {
    public var warnings: [String]?

    public init(warnings: [String]? = nil) {
        self.warnings = warnings
    }
}

/// Body for scaling a replicated swarm service.
public struct SwarmServiceScaleRequest: Codable, Hashable, Sendable {
    public var replicas: UInt64

    public init(replicas: UInt64) {
        self.replicas = replicas
    }
}
