import Foundation

public struct EnvironmentsService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    public func list() async throws -> [Environment] {
        try await rest.get("environments")
    }
}

public struct SystemService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    public func stats(envID: EnvironmentID? = nil, interval: Int = 2) -> StatsStream<SystemStatsFrame> {
        let env = envID ?? rest.defaultEnvironmentID
        return StatsStream(
            transport: rest.transport,
            path: "environments/\(env.rawValue)/ws/system/stats",
            query: [URLQueryItem(name: "interval", value: "\(interval)")]
        )
    }

    public func dockerInfo(envID: EnvironmentID? = nil) async throws -> DockerInfo {
        try await rest.get(rest.environmentPath(envID, "system/docker/info"))
    }

    public func appVersion() async throws -> VersionInfo {
        try await rest.get("app-version")
    }

    public func versionCheck(current: String? = nil) async throws -> VersionCheck {
        let query = current.map { [URLQueryItem(name: "current", value: $0)] } ?? []
        return try await rest.get("version", query: query)
    }

    public func upgradeCheck(envID: EnvironmentID? = nil) async throws -> UpgradeCheckResultData {
        let path = rest.environmentPath(envID, "system/upgrade/check")
        let data = try await rest.transport.rawRequest(path, body: Optional<EmptyBody>.none)
        do {
            return try ArcaneJSON.makeDecoder().decode(UpgradeCheckResultData.self, from: data)
        } catch {
            throw ArcaneError.decoding(String(describing: error))
        }
    }

    public func triggerUpgrade(envID: EnvironmentID? = nil) async throws -> MessageResponse {
        try await rest.post(rest.environmentPath(envID, "system/upgrade"), body: Optional<EmptyBody>.none)
    }
}

public struct ProjectsService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    public func logs(
        envID: EnvironmentID? = nil,
        id: String,
        follow: Bool = true,
        tail: String = "100",
        since: String? = nil,
        timestamps: Bool = false
    ) -> LogStream {
        let env = envID ?? rest.defaultEnvironmentID
        return LogStream(
            transport: rest.transport,
            path: "environments/\(env.rawValue)/ws/projects/\(id)/logs",
            query: LogStream.query(follow: follow, tail: tail, since: since, timestamps: timestamps)
        )
    }
}

public struct SwarmService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    public func serviceLogs(
        envID: EnvironmentID? = nil,
        id: String,
        follow: Bool = true,
        tail: String = "100",
        since: String? = nil,
        timestamps: Bool = false
    ) -> LogStream {
        let env = envID ?? rest.defaultEnvironmentID
        return LogStream(
            transport: rest.transport,
            path: "environments/\(env.rawValue)/ws/swarm/services/\(id)/logs",
            query: LogStream.query(follow: follow, tail: tail, since: since, timestamps: timestamps)
        )
    }
}
