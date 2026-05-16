import Foundation

/// BuildsService browses files in the build workspace for an environment.
public struct BuildsService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    /// List files and directories under the builds workspace root.
    public func browse(path: String = "/", envID: EnvironmentID? = nil) async throws -> [FileEntry] {
        let query = [URLQueryItem(name: "path", value: path)]
        return try await rest.get(rest.environmentPath(envID, "builds/browse"), query: query)
    }

    /// Read file content under the builds workspace root.
    public func getFileContent(path: String, maxBytes: Int64 = 1_048_576, envID: EnvironmentID? = nil) async throws -> BuildFileContent {
        let query: [URLQueryItem] = [
            URLQueryItem(name: "path", value: path),
            URLQueryItem(name: "maxBytes", value: "\(maxBytes)")
        ]
        return try await rest.get(rest.environmentPath(envID, "builds/browse/content"), query: query)
    }

    /// Create a directory under the builds workspace root.
    public func createDirectory(path: String, envID: EnvironmentID? = nil) async throws {
        let query = [URLQueryItem(name: "path", value: path)]
        try await rest.postVoid(rest.environmentPath(envID, "builds/browse/mkdir"), body: EmptyBody?.none, query: query)
    }

    /// Delete a file or directory under the builds workspace root.
    public func delete(path: String, envID: EnvironmentID? = nil) async throws {
        let query = [URLQueryItem(name: "path", value: path)]
        try await rest.deleteVoid(rest.environmentPath(envID, "builds/browse"), query: query)
    }
}
