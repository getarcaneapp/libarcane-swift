import Foundation

/// NotificationsService manages notification provider settings, Apprise integration, and dispatch.
public struct NotificationsService: Sendable {
  private let rest: RESTService

  init(rest: RESTService) {
    self.rest = rest
  }

  // MARK: - Provider settings

  /// Get all notification settings for an environment.
  public func listSettings(envID: EnvironmentID? = nil) async throws -> [NotificationSettings] {
    try await rawRequest(rest.environmentPath(envID, "notifications/settings"))
  }

  /// Get notification settings for a specific provider.
  public func getSettings(provider: NotificationProvider, envID: EnvironmentID? = nil) async throws
    -> NotificationSettings
  {
    try await rawRequest(rest.environmentPath(envID, "notifications/settings/\(provider.rawValue)"))
  }

  /// Create or update notification settings.
  public func upsertSettings(_ body: UpdateNotificationSettings, envID: EnvironmentID? = nil)
    async throws -> NotificationSettings
  {
    try await rawRequest(
      rest.environmentPath(envID, "notifications/settings"),
      method: "POST",
      body: body
    )
  }

  /// Delete notification settings for a provider.
  public func deleteSettings(provider: NotificationProvider, envID: EnvironmentID? = nil)
    async throws
  {
    try await rest.deleteVoid(
      rest.environmentPath(envID, "notifications/settings/\(provider.rawValue)"))
  }

  /// Send a test notification through the configured provider.
  public func test(
    provider: NotificationProvider, type: NotificationTestType = .simple,
    envID: EnvironmentID? = nil
  ) async throws -> NotificationTestResponse {
    let path = rest.environmentPath(envID, "notifications/test/\(provider.rawValue)")
    let query = [URLQueryItem(name: "type", value: type.rawValue)]
    return try await rest.post(path, body: EmptyBody?.none, query: query)
  }

  // MARK: - Apprise

  /// Get the Apprise integration settings.
  public func getAppriseSettings(envID: EnvironmentID? = nil) async throws -> AppriseSettings {
    try await rest.get(rest.environmentPath(envID, "notifications/apprise"))
  }

  /// Create or update Apprise integration settings.
  public func upsertAppriseSettings(_ body: UpdateAppriseSettings, envID: EnvironmentID? = nil)
    async throws -> AppriseSettings
  {
    try await rest.post(rest.environmentPath(envID, "notifications/apprise"), body: body)
  }

  /// Send a test notification through Apprise.
  public func testApprise(type: NotificationTestType = .simple, envID: EnvironmentID? = nil)
    async throws
  {
    let path = rest.environmentPath(envID, "notifications/apprise/test")
    let query = [URLQueryItem(name: "type", value: type.rawValue)]
    try await rest.postVoid(path, body: EmptyBody?.none, query: query)
  }

  // MARK: - Dispatch (manager-facing endpoint)

  /// Dispatch a notification from a remote agent to the manager.
  public func dispatch(_ body: NotificationDispatchRequest) async throws {
    try await rest.postVoid("notifications/dispatch", body: body)
  }

  private func rawRequest<T: Decodable & Sendable, Body: Encodable & Sendable>(
    _ path: String,
    method: String = "GET",
    body: Body? = nil
  ) async throws -> T {
    let data = try await rest.transport.rawRequest(path, method: method, body: body)
    do {
      return try rest.transport.decoder.decode(T.self, from: data)
    } catch {
      throw ArcaneError.decoding(String(describing: error))
    }
  }

  private func rawRequest<T: Decodable & Sendable>(_ path: String) async throws -> T {
    try await rawRequest(path, body: Optional<EmptyBody>.none)
  }
}
