import ArcaneAPI
import Foundation
import OpenAPIRuntime

public struct UpdaterService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    public func status(envID: EnvironmentID? = nil) async throws -> UpdaterStatus {
        try await rest.get(rest.environmentPath(envID, "updater/status"))
    }

    public func history(envID: EnvironmentID? = nil, limit: Int? = nil) async throws -> [AutoUpdateRecord] {
        let query = limit.map { [URLQueryItem(name: "limit", value: "\($0)")] } ?? []
        let records: [AutoUpdateRecord]? = try await rest.get(rest.environmentPath(envID, "updater/history"), query: query)
        return records ?? []
    }

    public func run(envID: EnvironmentID? = nil, dryRun: Bool = false) async throws -> UpdaterResult {
        let body = UpdaterOptions(dryRun: dryRun)
        return try await rest.post(rest.environmentPath(envID, "updater/run"), body: Optional.some(body))
    }
}

extension AutoUpdateRecord: Identifiable {}

extension AutoUpdateRecord {
    public var oldImageVersionsMap: [String: String] {
        Self.flatten(oldImageVersions?.additionalProperties)
    }

    public var newImageVersionsMap: [String: String] {
        Self.flatten(newImageVersions?.additionalProperties)
    }

    private static func flatten(_ values: [String: OpenAPIValueContainer]?) -> [String: String] {
        guard let values else { return [:] }
        var out: [String: String] = [:]
        for (key, container) in values {
            if let str = container.value as? String {
                out[key] = str
            } else if let value = container.value {
                out[key] = String(describing: value)
            }
        }
        return out
    }
}
