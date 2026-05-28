import Foundation

/// One permission grant on an API key, optionally scoped to a single
/// environment. Used by the v2 API-key create/update flow; API keys carry
/// independent permission sets (not inherited from the owner). When an API
/// key is created, the server validates that the caller holds every
/// permission being granted.
public struct ApiKeyPermissionGrant: Codable, Hashable, Sendable {
    public var permission: String
    public var environmentId: String?

    public init(permission: String, environmentId: String? = nil) {
        self.permission = permission
        self.environmentId = environmentId
    }
}
