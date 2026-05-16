import Foundation

/// Facade for the updater endpoints under `/environments/{id}/updater` and
/// `/environments/{id}/containers/{containerId}/update`.
public struct UpdaterService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    /// Runs the updater. When `options` is omitted the server uses its defaults.
    public func run(_ options: UpdaterOptions? = nil, envID: EnvironmentID? = nil) async throws -> UpdaterResult {
        try await rest.post(rest.environmentPath(envID, "updater/run"), body: options)
    }

    /// Returns the live updater status.
    public func status(envID: EnvironmentID? = nil) async throws -> UpdaterStatus {
        try await rest.get(rest.environmentPath(envID, "updater/status"))
    }

    /// Returns the most recent `limit` history records.
    public func history(limit: Int = 50, envID: EnvironmentID? = nil) async throws -> [AutoUpdateRecord] {
        try await rest.get(
            rest.environmentPath(envID, "updater/history"),
            query: [URLQueryItem(name: "limit", value: "\(limit)")]
        )
    }

    /// Updates a single container by pulling the latest image and applying the
    /// appropriate strategy server-side.
    public func updateContainer(_ containerId: String, envID: EnvironmentID? = nil) async throws -> UpdaterResult {
        try await rest.post(
            rest.environmentPath(envID, "containers/\(containerId)/update"),
            body: Optional<EmptyBody>.none
        )
    }
}
