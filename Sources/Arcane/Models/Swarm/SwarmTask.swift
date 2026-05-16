import Foundation

/// A swarm task summary (one row in a service's task list).
public struct SwarmTaskSummary: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var serviceId: String
    public var serviceName: String
    public var nodeId: String
    public var nodeName: String
    public var desiredState: String
    public var currentState: String
    public var error: String?
    public var containerId: String?
    public var image: String?
    public var slot: Int?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String,
        name: String,
        serviceId: String,
        serviceName: String,
        nodeId: String,
        nodeName: String,
        desiredState: String,
        currentState: String,
        error: String? = nil,
        containerId: String? = nil,
        image: String? = nil,
        slot: Int? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.serviceId = serviceId
        self.serviceName = serviceName
        self.nodeId = nodeId
        self.nodeName = nodeName
        self.desiredState = desiredState
        self.currentState = currentState
        self.error = error
        self.containerId = containerId
        self.image = image
        self.slot = slot
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
