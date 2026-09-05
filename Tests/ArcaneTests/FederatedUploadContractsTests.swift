import Foundation
import Testing

@testable import Arcane

@Suite(.serialized)
struct FederatedUploadContractsTests {
  @Test func federatedUpdatesPreserveFalseAndClearEnvironment() async throws {
    let client = makeClient()
    FederatedUploadProtocol.handler = { request in
      #expect(request.httpMethod == "PUT")
      #expect(request.url?.path == "/api/federated-credentials/rule")
      let body = try JSONSerialization.jsonObject(with: requestBody(request)) as! [String: Any]
      #expect(body["enabled"] as? Bool == false)
      #expect(body["environmentId"] as? String == "")
      #expect(body["name"] == nil)
      return (
        200,
        #"{"success":true,"data":{"id":"rule","name":"CI","enabled":false,"issuerUrl":"https://issuer.example","audiences":["arcane"],"subjectClaim":"sub","subjectMatch":"repo:org/repo:*","matchType":"glob","roleId":"role","environmentId":null,"identityUserId":"service","tokenTtlSeconds":300,"createdAt":"2026-09-04T12:00:00Z"}}"#
          .data(using: .utf8)!
      )
    }
    let credential = try await client.federatedCredentials.update(
      id: "rule", body: .init(enabled: false, environmentId: ""))
    #expect(credential.environmentId == nil)
    #expect(credential.matchType == "glob")
    #expect(!credential.enabled)
  }

  @Test func uploadReadsFileAsBinaryChunks() async throws {
    let client = makeClient()
    let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try Data([0, 1, 2, 3, 255]).write(to: file)
    defer { try? FileManager.default.removeItem(at: file) }
    FederatedUploadProtocol.handler = { request in
      let path = request.url!.path
      var received = "[]"
      var complete = false
      if path.hasSuffix("/chunks/0") {
        #expect(request.httpMethod == "PUT")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/octet-stream")
        #expect(try requestBody(request) == Data([0, 1, 2]))
        received = "[0]"
      } else if path.hasSuffix("/chunks/1") {
        #expect(try requestBody(request) == Data([3, 255]))
        received = "[0,1]"
        complete = true
      } else if request.httpMethod == "POST" {
        #expect(path == "/api/environments/fleet/uploads/volume-backup")
        let body = try JSONSerialization.jsonObject(with: requestBody(request)) as! [String: Any]
        #expect(body["size"] as? Int == 5)
      } else {
        #expect(request.httpMethod == "GET")
        #expect(path == "/api/environments/fleet/uploads/volume-backup/session")
        received = "[0,1]"
        complete = true
      }
      let json =
        "{\"success\":true,\"data\":{\"id\":\"session\",\"kind\":\"volume-backup\",\"filename\":\"backup.tar\",\"size\":5,\"chunkSize\":3,\"totalChunks\":2,\"receivedChunks\":\(received),\"complete\":\(complete),\"createdAt\":\"2026-09-04T12:00:00Z\"}}"
      return (200, Data(json.utf8))
    }
    let id = try await client.uploads.uploadFile(
      envID: .init(rawValue: "fleet"), kind: .volumeBackup, fileURL: file)
    #expect(id == "session")
  }

  @Test func binaryTransportPropagatesForbidden() async throws {
    FederatedUploadProtocol.handler = { _ in (403, Data(#"{"message":"forbidden"}"#.utf8)) }
    await #expect(throws: ArcaneError.forbidden) {
      _ = try await makeClient().uploads.putChunk(
        kind: .volumeBackup, id: "session", index: 0, data: Data([0]))
    }
  }

  private func makeClient() -> ArcaneClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [FederatedUploadProtocol.self]
    return ArcaneClient(
      configuration: .init(
        baseURL: URL(string: "https://example.test/api")!,
        urlSession: URLSession(configuration: configuration)))
  }
}

private func requestBody(_ request: URLRequest) throws -> Data {
  if let data = request.httpBody { return data }
  guard let stream = request.httpBodyStream else { return Data() }
  stream.open()
  defer { stream.close() }
  var data = Data()
  var buffer = [UInt8](repeating: 0, count: 4096)
  while stream.hasBytesAvailable {
    let count = stream.read(&buffer, maxLength: buffer.count)
    guard count >= 0 else { throw stream.streamError ?? URLError(.cannotDecodeRawData) }
    if count == 0 { break }
    data.append(buffer, count: count)
  }
  return data
}

private final class FederatedUploadProtocol: URLProtocol, @unchecked Sendable {
  nonisolated(unsafe) static var handler: (@Sendable (URLRequest) throws -> (Int, Data))?
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    do {
      let (status, data) = try Self.handler!(request)
      let response = HTTPURLResponse(
        url: request.url!, statusCode: status, httpVersion: nil,
        headerFields: ["Content-Type": "application/json"])!
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch { client?.urlProtocol(self, didFailWithError: error) }
  }
  override func stopLoading() {}
}
