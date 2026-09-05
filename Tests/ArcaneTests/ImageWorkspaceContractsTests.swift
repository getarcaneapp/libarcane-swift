import Foundation
import Testing

@testable import Arcane

@Suite(.serialized)
struct ImageWorkspaceContractsTests {
  private func client() -> ArcaneClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return ArcaneClient(
      configuration: .init(
        baseURL: URL(string: "https://arcane.example.com")!,
        urlSession: URLSession(configuration: configuration)))
  }

  @Test func searchPreservesSpecialCharacters() async throws {
    await MockURLProtocol.reset()
    await MockURLProtocol.setHandler { request in
      #expect(request.httpMethod == "GET")
      #expect(request.url?.path == "/api/environments/0/images/search")
      let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems
      #expect(query?.first(where: { $0.name == "term" })?.value == "org/image & other")
      return (
        HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
        Data(
          #"{"success":true,"data":[{"name":"org/image","description":"test","starCount":4,"official":false,"automated":true}]}"#
            .utf8)
      )
    }
    let result = try await client().images.search(term: "org/image & other")
    #expect(result.first?.name == "org/image")
    #expect(result.first?.automated == true)
  }

  @Test func patchReturnsRunningRecordAndEncodesScanSelection() async throws {
    await MockURLProtocol.reset()
    await MockURLProtocol.setHandler { request in
      #expect(request.httpMethod == "POST")
      #expect(request.url?.path == "/api/environments/0/images/sha256:abc/patch")
      let body =
        try JSONSerialization.jsonObject(with: workspaceRequestBody(request)) as! [String: Any]
      #expect(body["scanId"] as? String == "scan-1")
      #expect(body["ignoreErrors"] as? Bool == false)
      #expect(body["suffix"] == nil)
      return (
        HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
        Data(
          #"{"success":true,"data":{"id":"p1","environmentId":"0","originalImageId":"sha256:abc","originalRef":"org/image:latest","patchedRef":"org/image:patched","mode":"report","status":"patching","activityId":"a1","createdAt":"2026-09-04T01:02:03Z"}}"#
            .utf8)
      )
    }
    let patch = try await client().images.patch(
      imageID: "sha256:abc",
      options: .init(scanId: "scan-1", ignoreErrors: false))
    #expect(patch.status == "patching")
    #expect(patch.activityId == "a1")
    #expect(patch.packagesUpdated == nil)
  }

  @Test func workspaceUsesMultipartManifestAndFileIndex() async throws {
    await MockURLProtocol.reset()
    let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try Data("replacement".utf8).write(to: file)
    defer { try? FileManager.default.removeItem(at: file) }
    await MockURLProtocol.setHandler { request in
      #expect(request.httpMethod == "PUT")
      #expect(request.url?.path == "/api/environments/0/volumes/my volume/workspace")
      let body = String(decoding: try workspaceRequestBody(request), as: UTF8.self)
      #expect(body.contains(#"name="manifest""#))
      #expect(body.contains(#""fileTreeRevision":"rev-1""#))
      #expect(body.contains(#""uploadIndex":0"#))
      #expect(body.contains(#"name="files""#))
      #expect(body.contains("replacement"))
      return (
        HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
        Data(
          #"{"success":true,"data":{"files":[],"fileTreeRevision":"rev-2","fileTreeTruncated":false,"activityId":"a2"}}"#
            .utf8)
      )
    }
    let result = try await client().volumes.updateWorkspace(
      name: "my volume",
      manifest: .init(
        fileTreeRevision: "rev-1",
        fileChanges: [
          .init(operation: .updateFile, relativePath: "config/site.conf", uploadIndex: 0)
        ]), files: [file])
    #expect(result.fileTreeRevision == "rev-2")
    #expect(result.activityID == "a2")
  }

  @Test func workspaceFilePreservesPathAndReadOnlyReason() async throws {
    await MockURLProtocol.reset()
    await MockURLProtocol.setHandler { request in
      let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems
      #expect(query?.first(where: { $0.name == "relativePath" })?.value == "folder/a & b.bin")
      return (
        HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
        Data(
          #"{"success":true,"data":{"path":"/folder/a & b.bin","relativePath":"folder/a & b.bin","name":"a & b.bin","mimeType":"application/octet-stream","size":7,"editable":false,"readOnlyReason":"binary"}}"#
            .utf8)
      )
    }
    let file = try await client().volumes.workspaceFile(
      name: "data", relativePath: "folder/a & b.bin")
    #expect(file.content == nil)
    #expect(file.editable == false)
    #expect(file.readOnlyReason == "binary")
  }

  @Test func tagEncodesRepositoryReferenceInBody() async throws {
    await MockURLProtocol.reset()
    await MockURLProtocol.setHandler { request in
      #expect(request.httpMethod == "POST")
      #expect(request.url?.path == "/api/environments/0/images/sha256:abc/tag")
      let body =
        try JSONSerialization.jsonObject(with: workspaceRequestBody(request)) as! [String: Any]
      #expect(body["repository"] as? String == "registry:5000/team/image")
      #expect(body["tag"] == nil)
      return (
        HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
        Data(#"{"success":true,"data":{"message":"Image tagged"}}"#.utf8)
      )
    }
    _ = try await client().images.tag(
      imageID: "sha256:abc", request: .init(repository: "registry:5000/team/image"))
  }

  @Test func patchHistoryPreservesPaginationAndStatus() async throws {
    await MockURLProtocol.reset()
    await MockURLProtocol.setHandler { request in
      #expect(request.url?.path == "/api/environments/0/images/patches")
      let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
      #expect(query.filter { $0.name == "start" }.map(\.value) == ["30"])
      #expect(query.first { $0.name == "limit" }?.value == "10")
      #expect(query.first { $0.name == "status" }?.value == "failed")
      return (
        HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
        Data(
          #"{"success":true,"data":[],"pagination":{"totalItems":30,"totalPages":3,"currentPage":4,"itemsPerPage":10}}"#
            .utf8)
      )
    }
    let response = try await client().images.listPatches(
      query: .init(start: 30, limit: 10), status: "failed")
    #expect(response.data.isEmpty)
  }

  @Test func workspaceRejectsInvalidUploadIndices() async throws {
    do {
      _ = try await client().volumes.updateWorkspace(
        name: "data",
        manifest: .init(
          fileTreeRevision: "revision",
          fileChanges: [
            .init(operation: .updateFile, relativePath: "a", uploadIndex: 0)
          ]))
      Issue.record("Expected validation error")
    } catch ArcaneError.validation {}
  }
}

private func workspaceRequestBody(_ request: URLRequest) throws -> Data {
  if let data = request.httpBody { return data }
  let stream = try #require(request.httpBodyStream)
  stream.open()
  defer { stream.close() }
  var result = Data()
  var bytes = [UInt8](repeating: 0, count: 4096)
  while true {
    let count = stream.read(&bytes, maxLength: bytes.count)
    guard count >= 0 else { throw ArcaneError.transport("Unable to read test request") }
    if count == 0 { return result }
    result.append(bytes, count: count)
  }
}
