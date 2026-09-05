import Foundation

extension VolumesService {
  public func workspace(envID: EnvironmentID? = nil, name: String) async throws -> VolumeWorkspace {
    try await rest.get(rest.environmentPath(envID, "volumes/\(name)/workspace"))
  }

  public func workspaceFile(
    envID: EnvironmentID? = nil, name: String,
    relativePath: String
  ) async throws -> VolumeWorkspaceFileContent {
    try await rest.get(
      rest.environmentPath(envID, "volumes/\(name)/workspace/file"),
      query: [URLQueryItem(name: "relativePath", value: relativePath)])
  }

  public func downloadWorkspaceFile(
    envID: EnvironmentID? = nil, name: String,
    relativePath: String, to destinationURL: URL
  ) async throws {
    try await rest.transport.downloadRaw(
      rest.environmentPath(envID, "volumes/\(name)/workspace/file/download"),
      query: [URLQueryItem(name: "relativePath", value: relativePath)], to: destinationURL)
  }

  /// Atomically apply a revision-checked workspace manifest. Files are streamed from disk.
  /// A conflict is returned to the caller without refreshing or retrying the mutation.
  public func updateWorkspace(
    envID: EnvironmentID? = nil, name: String,
    manifest: VolumeWorkspaceUpdateManifest, files: [URL] = []
  ) async throws -> VolumeWorkspace {
    guard !manifest.fileTreeRevision.isEmpty, (1...500).contains(manifest.fileChanges.count) else {
      throw ArcaneError.validation(fields: [
        "manifest": ["A revision and 1 to 500 changes are required."]
      ])
    }
    for change in manifest.fileChanges {
      for index in [change.uploadIndex, change.baselineIndex].compactMap({ $0 }) {
        guard files.indices.contains(index) else {
          throw ArcaneError.validation(fields: [
            "files": ["Upload index is outside the supplied files."]
          ])
        }
      }
      if change.operation == .createFile || change.operation == .updateFile {
        guard change.uploadIndex != nil else {
          throw ArcaneError.validation(fields: [
            "files": ["Create and update operations require a file upload."]
          ])
        }
      }
    }
    let data = try ArcaneJSON.makeEncoder().encode(manifest)
    let uploads = files.map {
      MultipartFile(fieldName: "files", filename: $0.lastPathComponent, fileURL: $0)
    }
    return try await rest.transport.multipartUpload(
      rest.environmentPath(envID, "volumes/\(name)/workspace"), method: "PUT",
      fields: ["manifest": String(decoding: data, as: UTF8.self)], files: uploads)
  }
}
