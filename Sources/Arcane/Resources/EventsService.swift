import Foundation
import ArcaneAPI
import OpenAPIRuntime

public struct EventsService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    public func list(
        start: Int = 0,
        limit: Int = 50,
        search: String? = nil,
        severity: String? = nil,
        type: String? = nil
    ) async throws -> [Event] {
        var query: [URLQueryItem] = []
        if start > 0 { query.append(URLQueryItem(name: "start", value: "\(start)")) }
        query.append(URLQueryItem(name: "limit", value: "\(limit)"))
        if let search, !search.trimmingCharacters(in: .whitespaces).isEmpty {
            query.append(URLQueryItem(name: "search", value: search))
        }
        if let severity, !severity.isEmpty {
            query.append(URLQueryItem(name: "severity", value: severity))
        }
        if let type, !type.isEmpty {
            query.append(URLQueryItem(name: "type", value: type))
        }
        let events: [Event]? = try await rest.get("events", query: query)
        return events ?? []
    }
}

extension Event: Identifiable {}

extension Event {
    public var metadataMap: [String: String] {
        guard let values = metadata?.additionalProperties else { return [:] }
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
