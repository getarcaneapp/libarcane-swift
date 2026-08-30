import Foundation

/// Facade for the version endpoints.
///
/// `/version` and `/app-version` return their payloads *without* the standard
/// `{success, data}` envelope, so we go through `rawRequest` and decode the
/// body type directly. `/environments/{id}/version` is wrapped normally.
public struct VersionService: Sendable {
  private let rest: RESTService

  init(rest: RESTService) {
    self.rest = rest
  }

  /// Returns a simplified version check, optionally comparing against a
  /// caller-supplied `current` version.
  public func check(current: String? = nil) async throws -> VersionCheck {
    var query: [URLQueryItem] = []
    if let current {
      query.append(URLQueryItem(name: "current", value: current))
    }
    let data = try await rest.transport.rawRequest(
      "version",
      method: "GET",
      query: query,
      body: Optional<EmptyBody>.none,
      authorized: false
    )
    do {
      return try ArcaneJSON.makeDecoder().decode(VersionCheck.self, from: data)
    } catch {
      throw ArcaneError.decoding(String(describing: error))
    }
  }

  /// Returns the full application version info for the local API server.
  public func appVersion() async throws -> VersionInfo {
    let data = try await rest.transport.rawRequest(
      "app-version",
      method: "GET",
      body: Optional<EmptyBody>.none,
      authorized: false
    )
    let info: VersionInfo
    do {
      info = try ArcaneJSON.makeDecoder().decode(VersionInfo.self, from: data)
    } catch {
      throw ArcaneError.decoding(String(describing: error))
    }
    await rest.transport.authManager.recordEnabledFeatures(info.enabledFeatures ?? [])
    return info
  }

  /// Returns the application version info for a remote environment.
  public func environmentVersion(envID: EnvironmentID? = nil) async throws -> VersionInfo {
    try await rest.get(rest.environmentPath(envID, "version"))
  }
}
