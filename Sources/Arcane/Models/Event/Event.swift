import Foundation

public struct Event: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var type: String
    public var severity: String
    public var title: String
    public var description: String?
    public var resourceType: String?
    public var resourceId: String?
    public var resourceName: String?
    public var userId: String?
    public var username: String?
    public var environmentId: String?
    public var metadata: [String: JSONValue]?
    public var timestamp: Date
    public var createdAt: Date
    public var updatedAt: Date?

    public enum CodingKeys: String, CodingKey {
        case id
        case type
        case severity
        case title
        case description
        case resourceType
        case resourceId
        case resourceName
        case userId
        case username
        case environmentId
        case metadata
        case timestamp
        case createdAt
        case updatedAt
    }

    public init(
        id: String,
        type: String,
        severity: String,
        title: String,
        description: String? = nil,
        resourceType: String? = nil,
        resourceId: String? = nil,
        resourceName: String? = nil,
        userId: String? = nil,
        username: String? = nil,
        environmentId: String? = nil,
        metadata: [String: JSONValue]? = nil,
        timestamp: Date,
        createdAt: Date,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.severity = severity
        self.title = title
        self.description = description
        self.resourceType = resourceType
        self.resourceId = resourceId
        self.resourceName = resourceName
        self.userId = userId
        self.username = username
        self.environmentId = environmentId
        self.metadata = metadata
        self.timestamp = timestamp
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct CreateEvent: Codable, Hashable, Sendable {
    public var type: String
    public var severity: String?
    public var title: String
    public var description: String?
    public var resourceType: String?
    public var resourceId: String?
    public var resourceName: String?
    public var userId: String?
    public var username: String?
    public var environmentId: String?
    public var metadata: [String: JSONValue]?

    public init(
        type: String,
        severity: String? = nil,
        title: String,
        description: String? = nil,
        resourceType: String? = nil,
        resourceId: String? = nil,
        resourceName: String? = nil,
        userId: String? = nil,
        username: String? = nil,
        environmentId: String? = nil,
        metadata: [String: JSONValue]? = nil
    ) {
        self.type = type
        self.severity = severity
        self.title = title
        self.description = description
        self.resourceType = resourceType
        self.resourceId = resourceId
        self.resourceName = resourceName
        self.userId = userId
        self.username = username
        self.environmentId = environmentId
        self.metadata = metadata
    }
}
