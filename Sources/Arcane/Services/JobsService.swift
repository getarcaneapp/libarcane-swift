import Foundation

/// JobsService manages background job schedules and manual execution for an environment.
public struct JobsService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    /// Get configured cron schedules for background jobs.
    ///
    /// - Note: This endpoint returns the raw config object directly (without an ``APIResponse`` envelope),
    ///   so the request is unwrapped manually via the transport.
    public func getSchedules(envID: EnvironmentID? = nil) async throws -> JobScheduleConfig {
        let path = rest.environmentPath(envID, "job-schedules")
        let data = try await rest.transport.rawRequest(path, body: Optional<EmptyBody>.none)
        do {
            return try JSONDecoder.arcane.decode(JobScheduleConfig.self, from: data)
        } catch {
            throw ArcaneError.decoding(String(describing: error))
        }
    }

    /// Update background job cron schedules. Only non-nil fields are applied.
    public func updateSchedules(_ body: UpdateJobScheduleConfig, envID: EnvironmentID? = nil) async throws -> JobScheduleConfig {
        try await rest.put(rest.environmentPath(envID, "job-schedules"), body: body)
    }

    /// List all background jobs with their status, schedule, and metadata.
    ///
    /// - Note: This endpoint returns the list object directly (without an ``APIResponse`` envelope),
    ///   so the request is unwrapped manually via the transport.
    public func list(envID: EnvironmentID? = nil) async throws -> JobListResponse {
        let path = rest.environmentPath(envID, "jobs")
        let data = try await rest.transport.rawRequest(path, body: Optional<EmptyBody>.none)
        do {
            return try JSONDecoder.arcane.decode(JobListResponse.self, from: data)
        } catch {
            throw ArcaneError.decoding(String(describing: error))
        }
    }

    /// Manually trigger a background job to run immediately.
    ///
    /// - Note: This endpoint returns the run-response body directly (without an ``APIResponse`` envelope),
    ///   so the request is unwrapped manually via the transport.
    public func run(jobID: String, envID: EnvironmentID? = nil) async throws -> JobRunResponse {
        let path = rest.environmentPath(envID, "jobs/\(jobID)/run")
        let data = try await rest.transport.rawRequest(path, method: "POST", body: Optional<EmptyBody>.none)
        do {
            return try JSONDecoder.arcane.decode(JobRunResponse.self, from: data)
        } catch {
            throw ArcaneError.decoding(String(describing: error))
        }
    }
}

extension JSONDecoder {
    /// A shared decoder configured the same way ``ArcaneClient`` configures its decoders.
    fileprivate static let arcane: JSONDecoder = ArcaneJSON.makeDecoder()
}
