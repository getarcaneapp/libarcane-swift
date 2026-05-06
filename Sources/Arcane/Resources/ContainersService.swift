import Foundation

public struct ContainersService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    public func list(envID: EnvironmentID? = nil, query: [URLQueryItem] = []) async throws -> [ContainerSummary] {
        try await rest.get(rest.environmentPath(envID, "containers"), query: query)
    }

    public func inspect<T: Decodable & Sendable>(envID: EnvironmentID? = nil, id: String) async throws -> T {
        try await rest.get(rest.environmentPath(envID, "containers/\(id)"))
    }

    public func start(envID: EnvironmentID? = nil, id: String) async throws {
        let _: MessageResponse = try await rest.post(rest.environmentPath(envID, "containers/\(id)/start"), body: Optional<EmptyBody>.none)
    }

    public func stop(envID: EnvironmentID? = nil, id: String) async throws {
        let _: MessageResponse = try await rest.post(rest.environmentPath(envID, "containers/\(id)/stop"), body: Optional<EmptyBody>.none)
    }

    public func restart(envID: EnvironmentID? = nil, id: String) async throws {
        let _: MessageResponse = try await rest.post(rest.environmentPath(envID, "containers/\(id)/restart"), body: Optional<EmptyBody>.none)
    }

    public func logs(envID: EnvironmentID? = nil, id: String, follow: Bool = true, tail: String = "100", since: String? = nil, timestamps: Bool = false) -> LogStream {
        let env = envID ?? rest.defaultEnvironmentID
        return LogStream(
            transport: rest.transport,
            path: "environments/\(env.rawValue)/ws/containers/\(id)/logs",
            query: LogStream.query(follow: follow, tail: tail, since: since, timestamps: timestamps)
        )
    }

    public func stats(envID: EnvironmentID? = nil, id: String) -> StatsStream<JSONValue> {
        let env = envID ?? rest.defaultEnvironmentID
        return StatsStream(transport: rest.transport, path: "environments/\(env.rawValue)/ws/containers/\(id)/stats")
    }

    public func terminal(envID: EnvironmentID? = nil, id: String, shell: String = "/bin/sh") async throws -> TerminalSession {
        let env = envID ?? rest.defaultEnvironmentID
        return try await TerminalSession.connect(
            transport: rest.transport,
            path: "environments/\(env.rawValue)/ws/containers/\(id)/terminal",
            shell: shell
        )
    }
}
