import Foundation

nonisolated public struct NetworkInfo: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let driver: String
    public let scope: String
    public let isDefault: Bool
    public let inUse: Bool
    public let labels: [String: String]?
    public let options: [String: String]?
    public let created: Date?

    public var isInternal: Bool { false }
    public var containerCount: Int { 0 }
    public var attachable: Bool? { nil }
    public var ipam: NetworkIPAM? { nil }
    public var containers: [String: NetworkContainer]? { nil }
    public var labelsDictionary: [String: String] { labels ?? [:] }
    public var optionsDictionary: [String: String] { options ?? [:] }

    public enum CodingKeys: String, CodingKey {
        case id, name, driver, scope, isDefault, inUse, labels, options, created
    }

    nonisolated public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? ""
        self.driver = (try? container.decodeIfPresent(String.self, forKey: .driver)) ?? ""
        self.scope = (try? container.decodeIfPresent(String.self, forKey: .scope)) ?? ""
        self.isDefault = (try? container.decodeIfPresent(Bool.self, forKey: .isDefault)) ?? false
        self.inUse = (try? container.decodeIfPresent(Bool.self, forKey: .inUse)) ?? false
        self.labels = try? container.decodeIfPresent([String: String].self, forKey: .labels)
        self.options = try? container.decodeIfPresent([String: String].self, forKey: .options)
        self.created = try? container.decodeIfPresent(Date.self, forKey: .created)
    }
}

nonisolated public struct NetworkIPAM: Codable, Hashable, Sendable {
    public let driver: String?
    public let config: [NetworkIPAMConfig]?

    public init(driver: String? = nil, config: [NetworkIPAMConfig]? = nil) {
        self.driver = driver
        self.config = config
    }
}

nonisolated public struct NetworkIPAMConfig: Codable, Hashable, Sendable {
    public let subnet: String?
    public let gateway: String?

    public init(subnet: String? = nil, gateway: String? = nil) {
        self.subnet = subnet
        self.gateway = gateway
    }
}

nonisolated public struct NetworkContainer: Codable, Hashable, Sendable {
    public var name: String?
    public var endpointID: String?
    public var macAddress: String?
    public var iPv4Address: String?
    public var iPv6Address: String?

    public init(
        name: String? = nil,
        endpointID: String? = nil,
        macAddress: String? = nil,
        iPv4Address: String? = nil,
        iPv6Address: String? = nil
    ) {
        self.name = name
        self.endpointID = endpointID
        self.macAddress = macAddress
        self.iPv4Address = iPv4Address
        self.iPv6Address = iPv6Address
    }
}
