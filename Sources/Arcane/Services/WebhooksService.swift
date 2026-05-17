import Foundation

/// WebhooksService manages webhook resources scoped to an environment.
public struct WebhooksService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    /// List all webhooks configured for an environment. Tokens are masked.
    public func list(envID: EnvironmentID? = nil) async throws -> [Webhook] {
        try await rest.get(rest.environmentPath(envID, "webhooks"))
    }

    /// Create a new webhook. The raw token is returned only on creation.
    public func create(_ body: CreateWebhook, envID: EnvironmentID? = nil) async throws -> WebhookCreated {
        try await rest.post(rest.environmentPath(envID, "webhooks"), body: body)
    }

    /// Update a webhook's enabled state.
    public func update(id: String, body: UpdateWebhook, envID: EnvironmentID? = nil) async throws {
        let path = rest.environmentPath(envID, "webhooks/\(id)")
        let _: MessageResponse = try await rest.patch(path, body: body)
    }

    /// Delete a webhook.
    public func delete(id: String, envID: EnvironmentID? = nil) async throws {
        try await rest.deleteVoid(rest.environmentPath(envID, "webhooks/\(id)"))
    }
}
