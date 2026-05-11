import Foundation

public struct UpdaterService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    public func status(envID: EnvironmentID? = nil) async throws -> UpdaterStatus {
        try await rest.get(rest.environmentPath(envID, "updater/status"))
    }
}
