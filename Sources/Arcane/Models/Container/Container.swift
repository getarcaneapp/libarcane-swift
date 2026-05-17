import Foundation

/// A port binding for a container.
public struct ContainerPort: Codable, Hashable, Sendable {
    public var ip: String?
    public var privatePort: Int
    public var publicPort: Int?
    public var type: String

    public init(
        ip: String? = nil,
        privatePort: Int,
        publicPort: Int? = nil,
        type: String
    ) {
        self.ip = ip
        self.privatePort = privatePort
        self.publicPort = publicPort
        self.type = type
    }
}

/// A volume mount for a container.
public struct ContainerMount: Codable, Hashable, Sendable {
    public var type: String
    public var name: String?
    public var source: String?
    public var destination: String
    public var driver: String?
    public var mode: String?
    public var rw: Bool?
    public var propagation: String?

    public init(
        type: String,
        name: String? = nil,
        source: String? = nil,
        destination: String,
        driver: String? = nil,
        mode: String? = nil,
        rw: Bool? = nil,
        propagation: String? = nil
    ) {
        self.type = type
        self.name = name
        self.source = source
        self.destination = destination
        self.driver = driver
        self.mode = mode
        self.rw = rw
        self.propagation = propagation
    }
}

/// Network endpoint settings for a container.
public struct ContainerNetworkEndpoint: Codable, Hashable, Sendable {
    public var ipamConfig: JSONValue?
    public var links: [String]?
    public var aliases: [String]?
    public var macAddress: String?
    public var driverOpts: [String: String]?
    public var gwPriority: Int?
    public var networkId: String?
    public var endpointId: String?
    public var gateway: String?
    public var ipAddress: String?
    public var ipPrefixLen: Int?
    public var ipv6Gateway: String?
    public var globalIPv6Address: String?
    public var globalIPv6PrefixLen: Int?
    public var dnsNames: [String]?

    public init(
        ipamConfig: JSONValue? = nil,
        links: [String]? = nil,
        aliases: [String]? = nil,
        macAddress: String? = nil,
        driverOpts: [String: String]? = nil,
        gwPriority: Int? = nil,
        networkId: String? = nil,
        endpointId: String? = nil,
        gateway: String? = nil,
        ipAddress: String? = nil,
        ipPrefixLen: Int? = nil,
        ipv6Gateway: String? = nil,
        globalIPv6Address: String? = nil,
        globalIPv6PrefixLen: Int? = nil,
        dnsNames: [String]? = nil
    ) {
        self.ipamConfig = ipamConfig
        self.links = links
        self.aliases = aliases
        self.macAddress = macAddress
        self.driverOpts = driverOpts
        self.gwPriority = gwPriority
        self.networkId = networkId
        self.endpointId = endpointId
        self.gateway = gateway
        self.ipAddress = ipAddress
        self.ipPrefixLen = ipPrefixLen
        self.ipv6Gateway = ipv6Gateway
        self.globalIPv6Address = globalIPv6Address
        self.globalIPv6PrefixLen = globalIPv6PrefixLen
        self.dnsNames = dnsNames
    }
}

/// Network configuration for a container.
public struct ContainerNetworkSettings: Codable, Hashable, Sendable {
    public var networks: [String: ContainerNetworkEndpoint]

    public init(networks: [String: ContainerNetworkEndpoint] = [:]) {
        self.networks = networks
    }
}

/// Host configuration for a container.
public struct ContainerHostConfig: Codable, Hashable, Sendable {
    public var networkMode: String?
    public var restartPolicy: String?
    public var privileged: Bool?
    public var autoRemove: Bool?
    public var nanoCpus: Int64?
    public var memory: Int64?

    public init(
        networkMode: String? = nil,
        restartPolicy: String? = nil,
        privileged: Bool? = nil,
        autoRemove: Bool? = nil,
        nanoCpus: Int64? = nil,
        memory: Int64? = nil
    ) {
        self.networkMode = networkMode
        self.restartPolicy = restartPolicy
        self.privileged = privileged
        self.autoRemove = autoRemove
        self.nanoCpus = nanoCpus
        self.memory = memory
    }
}
