import Foundation

public struct UpdaterService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    public func status(envID: EnvironmentID? = nil) async throws -> UpdaterStatus {
        let envelope: StatusEnvelope = try await rest.get(rest.environmentPath(envID, "updater/status"))
        return envelope.data
    }

    private struct StatusEnvelope: Decodable, Sendable {
        let data: UpdaterStatus
    }
}
