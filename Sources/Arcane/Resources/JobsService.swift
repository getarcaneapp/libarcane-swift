import Foundation

public struct JobsService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    public func list(envID: EnvironmentID? = nil) async throws -> JobListResponse {
        try await fetchRaw(JobListResponse.self, path: rest.environmentPath(envID, "jobs"))
    }

    public func schedule(envID: EnvironmentID? = nil) async throws -> JobScheduleConfig {
        try await fetchRaw(JobScheduleConfig.self, path: rest.environmentPath(envID, "job-schedules"))
    }

    @discardableResult
    public func run(envID: EnvironmentID? = nil, id: String) async throws -> JobRunResponse {
        let escaped = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
        let path = rest.environmentPath(envID, "jobs/\(escaped)/run")
        let data = try await rest.transport.rawRequest(path, method: "POST", body: Optional<EmptyBody>.none)
        return try ArcaneJSON.makeDecoder().decode(JobRunResponse.self, from: data)
    }

    /// `/jobs` and `/job-schedules` return their payload at the top level
    /// (no `{ success, data }` wrapper), so we bypass the transport's
    /// `APIResponse<T>` unwrap and decode the body directly.
    private func fetchRaw<T: Decodable & Sendable>(_ type: T.Type, path: String) async throws -> T {
        let data = try await rest.transport.rawRequest(path, body: Optional<EmptyBody>.none)
        return try ArcaneJSON.makeDecoder().decode(T.self, from: data)
    }
}

extension JobStatus: Identifiable {}
