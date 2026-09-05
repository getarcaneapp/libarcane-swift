import Foundation
import Testing

@testable import Arcane

@Suite struct ContainerEditingContractsTests {
  @Test func editPreservesOmittedFieldsAndEncodesExplicitClears() throws {
    let encoder = JSONEncoder()
    let empty = try #require(
      JSONSerialization.jsonObject(with: encoder.encode(ContainerEdit())) as? [String: Any])
    #expect(empty.isEmpty)
    let edit = ContainerEdit(
      workingDir: "", command: [], environment: [], labels: [:], clearHealthcheck: true,
      hostConfig: .init(
        binds: [], mounts: [], portBindings: [:], privileged: false,
        capAdd: [], autoRemove: false, readonlyRootfs: false, memory: 0),
      networkingConfig: .init(endpointsConfig: [:]))
    let object = try #require(
      JSONSerialization.jsonObject(with: encoder.encode(edit)) as? [String: Any])
    #expect(object["image"] == nil)
    #expect(object["workingDir"] as? String == "")
    #expect((object["command"] as? [String])?.isEmpty == true)
    #expect((object["labels"] as? [String: String])?.isEmpty == true)
    let host = try #require(object["hostConfig"] as? [String: Any])
    #expect(host["privileged"] as? Bool == false)
    #expect(host["memory"] as? Int == 0)
    #expect((host["binds"] as? [String])?.isEmpty == true)
  }

  @Test func healthcheckAndMountCreateWireFormat() throws {
    let body = ContainerCreate(
      name: "test", image: "registry.example/team/image:tag",
      healthcheck: .init(test: ["CMD", "true"], interval: 30, timeout: 5, startInterval: 2),
      hostConfig: .init(
        capAdd: ["NET_ADMIN"],
        mounts: [
          .init(type: "bind", source: "/folder with spaces", target: "/data", readOnly: true)
        ]),
      networkingConfig: .init(endpointsConfig: ["net": .init(ipv4Address: "172.20.0.3")]))
    let encoded = try JSONEncoder().encode(body)
    let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    #expect((object["healthcheck"] as? [String: Any])?["interval"] as? Int == 30)
    #expect(try JSONDecoder().decode(ContainerCreate.self, from: encoded) == body)
  }

  @Test func servicesUseBackendRoutesAndEnvelopes() async throws {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [ContainerEditingProtocol.self]
    let client = ArcaneClient(
      configuration: .init(
        baseURL: URL(string: "https://container-contract.example")!,
        urlSession: URLSession(configuration: configuration)))
    let config = try await client.containers.editConfig(
      envID: .init(rawValue: "testing"), id: "old-id")
    #expect(config.id == "old-id")
    #expect(config.editDisabled == nil)
    #expect(config.hostConfig.privileged == nil)
    #expect(config.healthcheck?.interval == 30)
    #expect(config.networks?["test net"]?.ipv4Address == "172.20.0.3")
    let edited = try await client.containers.edit(
      envID: .init(rawValue: "testing"), id: "old-id", body: .init(command: []))
    #expect(edited.id == "new-id")
    #expect(edited.activityID == "activity-1")
    let committed = try await client.containers.commit(
      envID: .init(rawValue: "testing"), id: "old-id",
      body: .init(repository: "team/image", comment: "a comment", noPause: false))
    #expect(committed.id == "sha256:result")
    let compose = try await client.containers.generateCompose(
      envID: .init(rawValue: "testing"), body: .init(containerIds: ["old-id", "second-id"]))
    #expect(compose.composeContent == "services: {}")
  }
}

private final class ContainerEditingProtocol: URLProtocol, @unchecked Sendable {
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    do {
      let url = try #require(request.url)
      #expect(url.path.hasPrefix("/api/environments/testing/containers/"))
      let suffix = url.lastPathComponent
      var payload: String
      if suffix == "edit-config" {
        #expect(request.httpMethod == "GET")
        payload =
          #"{"id":"old-id","name":"test","image":"test:latest","running":false,"hostConfig":{"restartPolicy":{}},"healthcheck":{"interval":30},"networks":{"test net":{"ipv4Address":"172.20.0.3"}}}"#
      } else {
        #expect(request.httpMethod == "POST")
        var data = request.httpBody ?? Data()
        if let stream = request.httpBodyStream {
          stream.open()
          defer { stream.close() }
          var buffer = [UInt8](repeating: 0, count: 1024)
          while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }
            data.append(contentsOf: buffer.prefix(count))
          }
        }
        let body = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        switch suffix {
        case "edit":
          #expect(url.path.hasSuffix("/old-id/edit"))
          #expect((body["command"] as? [String])?.isEmpty == true)
          #expect(body["image"] == nil)
          payload =
            #"{"id":"new-id","name":"","image":"","imageId":"","created":"","state":{"status":"","running":false},"config":{},"hostConfig":{},"networkSettings":{"networks":{}},"ports":[],"mounts":[],"activityId":"activity-1"}"#
        case "commit":
          #expect(url.path.hasSuffix("/old-id/commit"))
          #expect(body["repository"] as? String == "team/image")
          #expect(body["noPause"] as? Bool == false)
          payload = #"{"id":"sha256:result"}"#
        case "generate-compose":
          #expect(body["containerIds"] as? [String] == ["old-id", "second-id"])
          payload = #"{"composeContent":"services: {}"}"#
        default:
          throw URLError(.badURL)
        }
      }
      let response = try #require(
        HTTPURLResponse(
          url: url, statusCode: 200, httpVersion: nil,
          headerFields: ["Content-Type": "application/json"]))
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: Data("{\"success\":true,\"data\":\(payload)}".utf8))
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }
  override func stopLoading() {}
}
