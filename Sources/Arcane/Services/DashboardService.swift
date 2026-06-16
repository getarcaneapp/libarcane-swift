import Foundation

/// Facade for the dashboard endpoints.
public struct DashboardService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    /// Returns the per-environment dashboard first-paint snapshot.
    public func snapshot(envID: EnvironmentID? = nil, debugAllGood: Bool = false) async throws -> DashboardSnapshot {
        try await rest.get(
            rest.environmentPath(envID, "dashboard"),
            query: Self.debugQuery(debugAllGood)
        )
    }

    /// Returns just the dashboard action items that currently need attention.
    public func actionItems(envID: EnvironmentID? = nil, debugAllGood: Bool = false) async throws -> ActionItems {
        try await rest.get(
            rest.environmentPath(envID, "dashboard/action-items"),
            query: Self.debugQuery(debugAllGood)
        )
    }

    /// Returns the aggregate dashboard overview across every visible environment.
    public func environmentsOverview(debugAllGood: Bool = false) async throws -> DashboardEnvironmentsOverview {
        try await rest.get("dashboard/environments", query: Self.debugQuery(debugAllGood))
    }

    /// Stream dashboard snapshot updates for the local environment and every
    /// enabled remote environment as NDJSON over a single connection. Global
    /// endpoint — not environment-scoped. Snapshot events have their
    /// container/image table rows trimmed; only the aggregate counts,
    /// action items, settings, and version info are populated.
    public func stream(debugAllGood: Bool = false) -> NDJSONStream<DashboardStreamEvent> {
        NDJSONStream(
            transport: rest.transport,
            path: "dashboard/stream",
            method: "GET",
            body: nil,
            contentType: nil,
            query: Self.debugQuery(debugAllGood)
        )
    }

    private static func debugQuery(_ debugAllGood: Bool) -> [URLQueryItem] {
        guard debugAllGood else { return [] }
        return [URLQueryItem(name: "debugAllGood", value: "true")]
    }
}
