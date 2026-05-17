import Foundation

public struct ContainersService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    // MARK: - Listing

    /// Paginated list of containers in an environment.
    public func list(
        envID: EnvironmentID? = nil,
        query: SearchPaginationSort = .init(),
        groupBy: String? = nil,
        includeInternal: Bool? = nil,
        updates: String? = nil,
        standalone: String? = nil
    ) async throws -> ContainerListResponse {
        var items = query.queryItems
        if let groupBy { items.append(URLQueryItem(name: "groupBy", value: groupBy)) }
        if let includeInternal { items.append(URLQueryItem(name: "includeInternal", value: includeInternal ? "true" : "false")) }
        if let updates { items.append(URLQueryItem(name: "updates", value: updates)) }
        if let standalone { items.append(URLQueryItem(name: "standalone", value: standalone)) }
        return try await rest.get(rest.environmentPath(envID, "containers"), query: items)
    }

    /// Container counts by status for an environment.
    public func statusCounts(
        envID: EnvironmentID? = nil,
        includeInternal: Bool? = nil
    ) async throws -> ContainerStatusCounts {
        var items: [URLQueryItem] = []
        if let includeInternal {
            items.append(URLQueryItem(name: "includeInternal", value: includeInternal ? "true" : "false"))
        }
        return try await rest.get(rest.environmentPath(envID, "containers/counts"), query: items)
    }

    // MARK: - CRUD

    /// Inspect a single container.
    public func inspect(envID: EnvironmentID? = nil, id: String) async throws -> ContainerDetails {
        try await rest.get(rest.environmentPath(envID, "containers/\(id)"))
    }

    /// Create a new container.
    public func create(envID: EnvironmentID? = nil, body: ContainerCreate) async throws -> ContainerCreated {
        try await rest.post(rest.environmentPath(envID, "containers"), body: body)
    }

    /// Delete a container, optionally forcing removal of running containers and removing associated volumes.
    public func delete(
        envID: EnvironmentID? = nil,
        id: String,
        force: Bool = false,
        removeVolumes: Bool = false
    ) async throws {
        let query: [URLQueryItem] = [
            URLQueryItem(name: "force", value: force ? "true" : "false"),
            URLQueryItem(name: "volumes", value: removeVolumes ? "true" : "false")
        ]
        try await rest.deleteVoid(rest.environmentPath(envID, "containers/\(id)"), query: query)
    }

    // MARK: - Lifecycle

    public func start(envID: EnvironmentID? = nil, id: String) async throws {
        try await rest.postVoid(rest.environmentPath(envID, "containers/\(id)/start"), body: Optional<EmptyBody>.none)
    }

    public func stop(envID: EnvironmentID? = nil, id: String) async throws {
        try await rest.postVoid(rest.environmentPath(envID, "containers/\(id)/stop"), body: Optional<EmptyBody>.none)
    }

    public func restart(envID: EnvironmentID? = nil, id: String) async throws {
        try await rest.postVoid(rest.environmentPath(envID, "containers/\(id)/restart"), body: Optional<EmptyBody>.none)
    }

    /// Redeploy a container: pulls the latest image and recreates the container.
    /// Returns the new container's details.
    public func redeploy(envID: EnvironmentID? = nil, id: String) async throws -> ContainerDetails {
        try await rest.post(rest.environmentPath(envID, "containers/\(id)/redeploy"), body: Optional<EmptyBody>.none)
    }

    /// Pause a running container.
    public func pause(envID: EnvironmentID? = nil, id: String) async throws {
        try await rest.postVoid(rest.environmentPath(envID, "containers/\(id)/pause"), body: Optional<EmptyBody>.none)
    }

    /// Resume a paused container.
    public func unpause(envID: EnvironmentID? = nil, id: String) async throws {
        try await rest.postVoid(rest.environmentPath(envID, "containers/\(id)/unpause"), body: Optional<EmptyBody>.none)
    }

    /// Send a signal to a running container (default: SIGKILL).
    public func kill(envID: EnvironmentID? = nil, id: String, signal: String = "SIGKILL") async throws {
        try await rest.postVoid(
            rest.environmentPath(envID, "containers/\(id)/kill"),
            body: Optional<EmptyBody>.none,
            query: [URLQueryItem(name: "signal", value: signal)]
        )
    }

    /// Rename an existing container.
    public func rename(envID: EnvironmentID? = nil, id: String, newName: String) async throws {
        try await rest.postVoid(
            rest.environmentPath(envID, "containers/\(id)/rename"),
            body: Optional<EmptyBody>.none,
            query: [URLQueryItem(name: "name", value: newName)]
        )
    }

    /// Enable or disable auto-update for a specific container.
    public func setAutoUpdate(envID: EnvironmentID? = nil, id: String, enabled: Bool) async throws {
        struct Body: Encodable, Sendable {
            let enabled: Bool
        }
        try await rest.putVoid(
            rest.environmentPath(envID, "containers/\(id)/auto-update"),
            body: Body(enabled: enabled)
        )
    }

    // MARK: - WebSocket streams

    /// Stream container log lines. Returns an `AsyncSequence` that finishes when the
    /// remote closes the WebSocket.
    public func logs(
        envID: EnvironmentID? = nil,
        id: String,
        follow: Bool = true,
        tail: String = "100",
        since: String? = nil,
        timestamps: Bool = false
    ) -> LogStream {
        let env = (envID ?? rest.defaultEnvironmentID).rawValue
        var query: [URLQueryItem] = [
            URLQueryItem(name: "follow", value: follow ? "true" : "false"),
            URLQueryItem(name: "tail", value: tail),
            URLQueryItem(name: "timestamps", value: timestamps ? "true" : "false")
        ]
        if let since {
            query.append(URLQueryItem(name: "since", value: since))
        }
        return LogStream(
            transport: rest.transport,
            path: "environments/\(env)/ws/containers/\(id)/logs",
            query: query
        )
    }

    /// Stream container resource usage stats over WebSocket.
    public func stats(
        envID: EnvironmentID? = nil,
        id: String
    ) -> StatsStream<ContainerStatsPayload> {
        let env = (envID ?? rest.defaultEnvironmentID).rawValue
        return StatsStream(
            transport: rest.transport,
            path: "environments/\(env)/ws/containers/\(id)/stats"
        )
    }

    /// Open an interactive terminal session against a running container.
    public func exec(
        envID: EnvironmentID? = nil,
        id: String,
        shell: String = "/bin/sh"
    ) async throws -> TerminalSession {
        let env = (envID ?? rest.defaultEnvironmentID).rawValue
        return try await TerminalSession.connect(
            transport: rest.transport,
            path: "environments/\(env)/ws/containers/\(id)/terminal",
            shell: shell
        )
    }
}
