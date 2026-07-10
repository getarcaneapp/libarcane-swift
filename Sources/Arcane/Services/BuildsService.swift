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
  public func getFileContent(path: String, maxBytes: Int64 = 1_048_576, envID: EnvironmentID? = nil)
    async throws -> BuildFileContent
  {
    let query: [URLQueryItem] = [
      URLQueryItem(name: "path", value: path),
      URLQueryItem(name: "maxBytes", value: "\(maxBytes)"),
    ]
    return try await rest.get(rest.environmentPath(envID, "builds/browse/content"), query: query)
  }

  /// Create a directory under the builds workspace root.
  public func createDirectory(path: String, envID: EnvironmentID? = nil) async throws {
    let query = [URLQueryItem(name: "path", value: path)]
    try await rest.postVoid(
      rest.environmentPath(envID, "builds/browse/mkdir"), body: EmptyBody?.none, query: query)
  }

  /// Delete a file or directory under the builds workspace root.
  public func delete(path: String, envID: EnvironmentID? = nil) async throws {
    let query = [URLQueryItem(name: "path", value: path)]
    try await rest.deleteVoid(rest.environmentPath(envID, "builds/browse"), query: query)
  }

  /// Upload a file into the build workspace at `path`.
  public func upload(
    path: String,
    fileURL: URL,
    filename: String? = nil,
    envID: EnvironmentID? = nil
  ) async throws {
    let part = MultipartFile(
      fieldName: "file",
      filename: filename ?? fileURL.lastPathComponent,
      fileURL: fileURL
    )
    let _: MessageResponse = try await rest.transport.multipartUpload(
      rest.environmentPath(envID, "builds/browse/upload"),
      query: [URLQueryItem(name: "path", value: path)],
      files: [part]
    )
  }

  /// Download the raw bytes of a file in the build workspace.
  @available(*, deprecated, message: "Use downloadFile(..., to:) for potentially large files.")
  public func downloadFile(path: String, envID: EnvironmentID? = nil) async throws -> Data {
    try await rest.transport.downloadRaw(
      rest.environmentPath(envID, "builds/browse/download"),
      query: [URLQueryItem(name: "path", value: path)]
    )
  }

  /// Download a build-workspace file directly to a destination URL.
  public func downloadFile(
    path: String,
    envID: EnvironmentID? = nil,
    to destinationURL: URL
  ) async throws {
    try await rest.transport.downloadRaw(
      rest.environmentPath(envID, "builds/browse/download"),
      query: [URLQueryItem(name: "path", value: path)],
      to: destinationURL
    )
  }
}
