import Foundation

/// Summary is returned in list responses; the token is masked.
public struct Webhook: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var tokenPrefix: String
    public var targetType: String
    public var actionType: String
    public var targetId: String
    public var targetName: String?
    public var environmentId: String
    public var enabled: Bool
    public var lastTriggeredAt: Date?
    public var createdAt: Date

    public init(
        id: String,
        name: String,
        tokenPrefix: String,
        targetType: String,
        actionType: String,
        targetId: String,
        targetName: String? = nil,
        environmentId: String,
        enabled: Bool,
        lastTriggeredAt: Date? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.tokenPrefix = tokenPrefix
        self.targetType = targetType
        self.actionType = actionType
        self.targetId = targetId
        self.targetName = targetName
        self.environmentId = environmentId
        self.enabled = enabled
        self.lastTriggeredAt = lastTriggeredAt
        self.createdAt = createdAt
    }
}

/// Returned once when a webhook is first created, including the raw token.
public struct WebhookCreated: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var token: String
    public var targetType: String
    public var actionType: String
    public var targetId: String
    public var createdAt: Date

    public init(
        id: String,
        name: String,
        token: String,
        targetType: String,
        actionType: String,
        targetId: String,
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.token = token
        self.targetType = targetType
        self.actionType = actionType
        self.targetId = targetId
        self.createdAt = createdAt
    }
}

public struct CreateWebhook: Codable, Hashable, Sendable {
    public var name: String
    public var targetType: String
    public var actionType: String
    public var targetId: String

    public init(name: String, targetType: String, actionType: String, targetId: String) {
        self.name = name
        self.targetType = targetType
        self.actionType = actionType
        self.targetId = targetId
    }
}

public struct UpdateWebhook: Codable, Hashable, Sendable {
    public var enabled: Bool

    public init(enabled: Bool) {
        self.enabled = enabled
    }
}
