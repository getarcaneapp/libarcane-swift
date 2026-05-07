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
