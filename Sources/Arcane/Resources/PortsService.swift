import Foundation

public struct PortsService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    public func list(envID: EnvironmentID? = nil) async throws -> [PortMapping] {
        try await rest.get(rest.environmentPath(envID, "ports"))
    }
}

extension PortMapping: Identifiable {}
