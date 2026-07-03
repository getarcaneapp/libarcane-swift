import Foundation

/// SettingsService manages application settings, search, and category metadata.
public struct SettingsService: Sendable {
  private let rest: RESTService

  init(rest: RESTService) {
    self.rest = rest
  }

  // MARK: - Per-environment settings

  /// Get all public settings for an environment (no auth required).
  ///
  /// - Note: The endpoint returns the list directly without an ``APIResponse`` envelope.
  public func getPublicSettings(envID: EnvironmentID? = nil) async throws -> [PublicSetting] {
    let path = rest.environmentPath(envID, "settings/public")
    let data = try await rest.transport.rawRequest(
      path, body: Optional<EmptyBody>.none, authorized: false)
    return try Self.decoder.decode([PublicSetting].self, from: data)
  }

  /// Get all settings visible to the current user for an environment.
  ///
  /// - Note: The endpoint returns the list directly without an ``APIResponse`` envelope.
  public func getSettings(envID: EnvironmentID? = nil) async throws -> [PublicSetting] {
    let path = rest.environmentPath(envID, "settings")
    let data = try await rest.transport.rawRequest(path, body: Optional<EmptyBody>.none)
    return try Self.decoder.decode([PublicSetting].self, from: data)
  }

  /// Update settings for an environment.
  public func updateSettings(_ body: UpdateSettings, envID: EnvironmentID? = nil) async throws
    -> [SettingDto]
  {
    try await rest.put(rest.environmentPath(envID, "settings"), body: body)
  }

  // MARK: - Top-level settings (search & categories)

  /// Search settings categories and individual settings by query.
  ///
  /// - Note: The endpoint returns the response directly without an ``APIResponse`` envelope.
  public func search(query: String) async throws -> SettingsSearchResponse {
    let body = SettingsSearchRequest(query: query)
    let data = try await rest.transport.rawRequest("settings/search", method: "POST", body: body)
    return try Self.decoder.decode(SettingsSearchResponse.self, from: data)
  }

  /// Get all available settings categories with metadata.
  ///
  /// - Note: The endpoint returns the list directly without an ``APIResponse`` envelope.
  public func categories() async throws -> [SettingCategory] {
    let data = try await rest.transport.rawRequest(
      "settings/categories", body: Optional<EmptyBody>.none)
    return try Self.decoder.decode([SettingCategory].self, from: data)
  }

  private static let decoder: JSONDecoder = ArcaneJSON.makeDecoder()
}
