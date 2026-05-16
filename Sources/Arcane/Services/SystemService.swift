import Foundation

/// Facade for system-level endpoints under `/environments/{id}/system`.
public struct SystemService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    // MARK: - Health / Info

    /// Top-level API health probe (`GET /health`) — does not hit Docker.
    /// Returns the parsed `HealthResponse` (`status == "UP"`) when the server
    /// responds with 2xx. Unauthenticated.
    public func apiHealth() async throws -> HealthResponse {
        let data = try await rest.transport.rawRequest(
            "health",
            method: "GET",
            body: Optional<EmptyBody>.none,
            authorized: false
        )
        do {
            return try ArcaneJSON.makeDecoder().decode(HealthResponse.self, from: data)
        } catch {
            throw ArcaneError.decoding(String(describing: error))
        }
    }

    /// Pings the Docker daemon for a specific environment. Throws an
    /// `ArcaneError` if the daemon is unreachable.
    public func health(envID: EnvironmentID? = nil) async throws {
        _ = try await rest.transport.rawRequest(
            rest.environmentPath(envID, "system/health"),
            method: "HEAD",
            body: Optional<EmptyBody>.none,
            authorized: true
        )
    }

    /// Returns the Docker daemon version and system info. The response is the
    /// merged `dockerinfo.Info` blob, returned without an `APIResponse` envelope.
    public func dockerInfo(envID: EnvironmentID? = nil) async throws -> DockerInfo {
        let data = try await rest.transport.rawRequest(
            rest.environmentPath(envID, "system/docker/info"),
            body: Optional<EmptyBody>.none,
            authorized: true
        )
        do {
            return try ArcaneJSON.makeDecoder().decode(DockerInfo.self, from: data)
        } catch {
            throw ArcaneError.decoding(String(describing: error))
        }
    }

    // MARK: - Prune

    /// Removes unused Docker resources according to `options`.
    public func prune(_ options: PruneAllRequest, envID: EnvironmentID? = nil) async throws -> PruneAllResult {
        try await rest.post(rest.environmentPath(envID, "system/prune"), body: options)
    }

    // MARK: - Bulk container actions

    /// Starts every container (creating them where necessary).
    public func startAllContainers(envID: EnvironmentID? = nil) async throws -> SystemContainerActionResult {
        try await rest.post(rest.environmentPath(envID, "system/containers/start-all"), body: Optional<EmptyBody>.none)
    }

    /// Starts every stopped container.
    public func startAllStoppedContainers(envID: EnvironmentID? = nil) async throws -> SystemContainerActionResult {
        try await rest.post(rest.environmentPath(envID, "system/containers/start-stopped"), body: Optional<EmptyBody>.none)
    }

    /// Stops every running container.
    public func stopAllContainers(envID: EnvironmentID? = nil) async throws -> SystemContainerActionResult {
        try await rest.post(rest.environmentPath(envID, "system/containers/stop-all"), body: Optional<EmptyBody>.none)
    }

    // MARK: - Convert / Upgrade

    /// Converts a `docker run ...` command-line into an equivalent compose document.
    /// The response is returned without the standard envelope.
    public func convertDockerRun(_ request: ConvertDockerRunRequest, envID: EnvironmentID? = nil) async throws -> ConvertDockerRunResponse {
        let data = try await rest.transport.rawRequest(
            rest.environmentPath(envID, "system/convert"),
            method: "POST",
            body: request,
            authorized: true
        )
        do {
            return try ArcaneJSON.makeDecoder().decode(ConvertDockerRunResponse.self, from: data)
        } catch {
            throw ArcaneError.decoding(String(describing: error))
        }
    }

    /// Checks whether Arcane can self-upgrade in this environment. The response
    /// is returned without the standard envelope.
    public func checkUpgrade(envID: EnvironmentID? = nil) async throws -> UpgradeCheckResult {
        let data = try await rest.transport.rawRequest(
            rest.environmentPath(envID, "system/upgrade/check"),
            method: "GET",
            body: Optional<EmptyBody>.none,
            authorized: true
        )
        do {
            return try ArcaneJSON.makeDecoder().decode(UpgradeCheckResult.self, from: data)
        } catch {
            throw ArcaneError.decoding(String(describing: error))
        }
    }

    /// Triggers a system upgrade. Returns once the upgrade has been scheduled
    /// (HTTP 202 is normal here — the server is mid-replacement).
    public func triggerUpgrade(envID: EnvironmentID? = nil) async throws {
        try await rest.postVoid(rest.environmentPath(envID, "system/upgrade"), body: Optional<EmptyBody>.none)
    }

    // MARK: - WebSocket streams

    /// Streams live system stats over a WebSocket connection.
    public func statsStream(envID: EnvironmentID? = nil) -> StatsStream<SystemStats> {
        StatsStream(transport: rest.transport, path: rest.environmentPath(envID, "ws/system/stats"))
    }
}
