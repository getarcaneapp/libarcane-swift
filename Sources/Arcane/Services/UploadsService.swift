import Foundation

public struct UploadsService: Sendable {
  private let rest: RESTService
  init(rest: RESTService) { self.rest = rest }

  public func create(envID: EnvironmentID? = nil, kind: UploadKind, body: CreateUploadSession)
    async throws -> UploadSession
  {
    try await rest.post(rest.environmentPath(envID, "uploads/\(kind.rawValue)"), body: body)
  }

  public func get(envID: EnvironmentID? = nil, kind: UploadKind, id: String) async throws
    -> UploadSession
  {
    try await rest.get(rest.environmentPath(envID, "uploads/\(kind.rawValue)/\(id)"))
  }

  public func delete(envID: EnvironmentID? = nil, kind: UploadKind, id: String) async throws {
    _ = try await rest.transport.rawRequest(
      rest.environmentPath(envID, "uploads/\(kind.rawValue)/\(id)"),
      method: "DELETE", body: Optional<EmptyBody>.none)
  }

  public func putChunk(
    envID: EnvironmentID? = nil, kind: UploadKind, id: String, index: Int, data: Data
  ) async throws -> UploadSession {
    let response = try await rest.transport.rawDataRequest(
      rest.environmentPath(envID, "uploads/\(kind.rawValue)/\(id)/chunks/\(index)"), body: data)
    return try rest.transport.decoder.decode(APIResponse<UploadSession>.self, from: response).data
  }

  /// Reads one server-sized chunk at a time. The completed session is consumed by a domain endpoint.
  public func uploadFile(
    envID: EnvironmentID? = nil, kind: UploadKind, fileURL: URL,
    onProgress: (@Sendable (UploadProgress) async -> Void)? = nil
  ) async throws -> String {
    let file = try FileHandle(forReadingFrom: fileURL)
    defer { try? file.close() }
    let size = try file.seekToEnd()
    guard size > 0, size <= UInt64(Int64.max) else {
      throw ArcaneError.transport("Invalid upload file size")
    }
    let session = try await create(
      envID: envID, kind: kind,
      body: .init(filename: fileURL.lastPathComponent, size: Int64(size)))
    do {
      guard session.chunkSize > 0, session.chunkSize <= 64 * 1024 * 1024,
        session.size == Int64(size),
        session.totalChunks == Int((size - 1) / UInt64(session.chunkSize) + 1)
      else { throw ArcaneError.transport("Invalid upload session dimensions") }
      var received = Set(session.receivedChunks)
      for index in 0..<session.totalChunks {
        try Task.checkCancellation()
        if !received.contains(index) {
          let offset = UInt64(index) * UInt64(session.chunkSize)
          try file.seek(toOffset: offset)
          let count = Int(min(UInt64(session.chunkSize), size - offset))
          guard let chunk = try file.read(upToCount: count), chunk.count == count else {
            throw ArcaneError.transport("Upload file changed while reading")
          }
          let updated = try await putChunk(
            envID: envID, kind: kind, id: session.id, index: index, data: chunk)
          received = Set(updated.receivedChunks)
        }
        let bytesDone = received.filter { $0 >= 0 && $0 < session.totalChunks }.reduce(Int64(0)) {
          $0 + min(Int64(session.chunkSize), Int64(size) - Int64($1) * Int64(session.chunkSize))
        }
        await onProgress?(.init(bytesDone: bytesDone, totalBytes: Int64(size)))
      }
      let final = try await get(envID: envID, kind: kind, id: session.id)
      guard final.complete else { throw ArcaneError.transport("Upload session is incomplete") }
      return session.id
    } catch {
      try? await delete(envID: envID, kind: kind, id: session.id)
      throw error
    }
  }
}
