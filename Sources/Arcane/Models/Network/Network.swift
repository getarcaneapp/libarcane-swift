import Foundation

/// NetworkSummary is the list/summary representation of a Docker network.
public struct NetworkSummary: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var driver: String
    public var scope: String
    public var created: Date
    public var options: [String: String]
    public var labels: [String: String]
    public var inUse: Bool
    public var isDefault: Bool

    public init(
        id: String,
        name: String,
        driver: String,
        scope: String,
        created: Date,
        options: [String: String] = [:],
        labels: [String: String] = [:],
        inUse: Bool = false,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.driver = driver
        self.scope = scope
        self.created = created
        self.options = options
        self.labels = labels
        self.inUse = inUse
        self.isDefault = isDefault
    }
}

/// NetworkUsageCounts contains counts of networks by usage status.
public struct NetworkUsageCounts: Codable, Hashable, Sendable {
    public var inuse: Int
    public var unused: Int
    public var total: Int

    public init(inuse: Int = 0, unused: Int = 0, total: Int = 0) {
        self.inuse = inuse
        self.unused = unused
        self.total = total
    }
}

/// IPAMConfig contains a single subnet's IPAM configuration.
public struct IPAMConfig: Codable, Hashable, Sendable {
    public var subnet: String?
    public var gateway: String?
    public var ipRange: String?
    public var auxAddress: [String: String]?

    public init(
        subnet: String? = nil,
        gateway: String? = nil,
        ipRange: String? = nil,
        auxAddress: [String: String]? = nil
    ) {
        self.subnet = subnet
        self.gateway = gateway
        self.ipRange = ipRange
        self.auxAddress = auxAddress
    }
}

/// IPAM is the IP Address Management configuration block.
public struct IPAM: Codable, Hashable, Sendable {
    public var driver: String?
    public var options: [String: String]?
    public var config: [IPAMConfig]?

    public init(
        driver: String? = nil,
        options: [String: String]? = nil,
        config: [IPAMConfig]? = nil
    ) {
        self.driver = driver
        self.options = options
        self.config = config
    }
}

/// NetworkContainerEndpoint represents one container attached to a network.
public struct NetworkContainerEndpoint: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var endpointId: String
    public var ipv4Address: String
    public var ipv6Address: String
    public var macAddress: String

    public init(
        id: String,
        name: String,
        endpointId: String,
        ipv4Address: String = "",
        ipv6Address: String = "",
        macAddress: String = ""
    ) {
        self.id = id
        self.name = name
        self.endpointId = endpointId
        self.ipv4Address = ipv4Address
        self.ipv6Address = ipv6Address
        self.macAddress = macAddress
    }
}

/// NetworkInspect is the detailed inspect view of a Docker network.
public struct NetworkInspect: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var driver: String
    public var scope: String
    public var created: Date
    public var enableIPv4: Bool
    public var enableIPv6: Bool
    public var ipam: IPAM
    public var `internal`: Bool
    public var attachable: Bool
    public var ingress: Bool
    public var configFrom: [String: JSONValue]?
    public var configOnly: Bool
    public var containers: [String: JSONValue]
    public var options: [String: String]
    public var labels: [String: String]
    public var peers: [JSONValue]?
    public var services: [String: JSONValue]?
    public var containersList: [NetworkContainerEndpoint]

    public init(
        id: String,
        name: String,
        driver: String,
        scope: String,
        created: Date,
        enableIPv4: Bool = false,
        enableIPv6: Bool = false,
        ipam: IPAM,
        internal: Bool = false,
        attachable: Bool = false,
        ingress: Bool = false,
        configFrom: [String: JSONValue]? = nil,
        configOnly: Bool = false,
        containers: [String: JSONValue] = [:],
        options: [String: String] = [:],
        labels: [String: String] = [:],
        peers: [JSONValue]? = nil,
        services: [String: JSONValue]? = nil,
        containersList: [NetworkContainerEndpoint] = []
    ) {
        self.id = id
        self.name = name
        self.driver = driver
        self.scope = scope
        self.created = created
        self.enableIPv4 = enableIPv4
        self.enableIPv6 = enableIPv6
        self.ipam = ipam
        self.internal = `internal`
        self.attachable = attachable
        self.ingress = ingress
        self.configFrom = configFrom
        self.configOnly = configOnly
        self.containers = containers
        self.options = options
        self.labels = labels
        self.peers = peers
        self.services = services
        self.containersList = containersList
    }
}

/// NetworkCreateOptions configures a network create request.
public struct NetworkCreateOptions: Codable, Hashable, Sendable {
    public var driver: String?
    public var checkDuplicate: Bool?
    public var `internal`: Bool?
    public var attachable: Bool?
    public var ingress: Bool?
    public var ipam: IPAM?
    public var enableIPv6: Bool?
    public var options: [String: String]?
    public var labels: [String: String]?

    public init(
        driver: String? = nil,
        checkDuplicate: Bool? = nil,
        internal: Bool? = nil,
        attachable: Bool? = nil,
        ingress: Bool? = nil,
        ipam: IPAM? = nil,
        enableIPv6: Bool? = nil,
        options: [String: String]? = nil,
        labels: [String: String]? = nil
    ) {
        self.driver = driver
        self.checkDuplicate = checkDuplicate
        self.internal = `internal`
        self.attachable = attachable
        self.ingress = ingress
        self.ipam = ipam
        self.enableIPv6 = enableIPv6
        self.options = options
        self.labels = labels
    }
}

/// NetworkCreateRequest is the body for ``POST environments/{id}/networks``.
public struct NetworkCreateRequest: Codable, Hashable, Sendable {
    public var name: String
    public var options: NetworkCreateOptions

    public init(name: String, options: NetworkCreateOptions = NetworkCreateOptions()) {
        self.name = name
        self.options = options
    }
}

/// NetworkCreateResponse is the response of a network create request.
public struct NetworkCreateResponse: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var warning: String?

    public init(id: String, warning: String? = nil) {
        self.id = id
        self.warning = warning
    }
}

/// NetworkPruneReport is the result of a network prune operation.
public struct NetworkPruneReport: Codable, Hashable, Sendable {
    public var networksDeleted: [String]
    public var spaceReclaimed: UInt64

    public init(networksDeleted: [String] = [], spaceReclaimed: UInt64 = 0) {
        self.networksDeleted = networksDeleted
        self.spaceReclaimed = spaceReclaimed
    }
}

/// NetworkListPage is the page envelope returned by ``GET /environments/{id}/networks``.
public struct NetworkListPage: Decodable, Sendable {
    public var success: Bool
    public var data: [NetworkSummary]
    public var counts: NetworkUsageCounts
    public var pagination: PaginationResponse
}
