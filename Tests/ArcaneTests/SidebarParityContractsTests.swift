import Foundation
import XCTest

@testable import Arcane

final class SidebarParityContractsTests: XCTestCase {
  func testImageHistoryDecodingAndRequestPath() async throws {
    await MockURLProtocol.reset()
    let client = makeClient()
    await MockURLProtocol.setHandler { request in
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.url?.path, "/api/environments/fleet/images/sha256:abc/history")
      return try response(
        for: request,
        body: #"{"success":true,"data":[{"id":"sha256:layer","created":1723032000,"createdBy":"RUN apk add curl","tags":["example:latest"],"size":2048,"comment":"buildkit"},{"id":"<missing>","created":0,"createdBy":"","tags":null,"size":0}]}"#
      )
    }

    let history = try await client.images.history(
      envID: EnvironmentID(rawValue: "fleet"),
      imageID: "sha256:abc"
    )

    XCTAssertEqual(history.count, 2)
    XCTAssertEqual(history.first?.id, "sha256:layer")
    XCTAssertEqual(history.first?.created, 1_723_032_000)
    XCTAssertEqual(history.first?.createdBy, "RUN apk add curl")
    XCTAssertEqual(history.first?.tags, ["example:latest"])
    XCTAssertEqual(history.first?.size, 2_048)
    XCTAssertEqual(history.last?.tags, [])
    XCTAssertEqual(history.last?.comment, "")
  }

  func testSelectiveProjectRestartUsesRepeatedQueryParameters() async throws {
    await MockURLProtocol.reset()
    let client = makeClient()
    await MockURLProtocol.setHandler { request in
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(request.url?.path, "/api/environments/0/projects/project/restart")
      let items = URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)?
        .queryItems
      XCTAssertEqual(items?.map(\.name), ["services", "services"])
      XCTAssertEqual(items?.compactMap(\.value), ["web", "worker"])
      return try response(
        for: request,
        body: #"{"success":true,"data":{"message":"restart started"}}"#
      )
    }

    _ = try await client.projects.restart(
      projectID: "project",
      services: ["web", "worker"]
    )
  }

  func testWholeProjectRestartOmitsServiceQuery() async throws {
    await MockURLProtocol.reset()
    let client = makeClient()
    await MockURLProtocol.setHandler { request in
      XCTAssertNil(request.url?.query)
      return try response(
        for: request,
        body: #"{"success":true,"data":{"message":"restart started"}}"#
      )
    }

    _ = try await client.projects.restart(projectID: "project")
  }

  func testTypedNetworkAccessorsIgnoreMalformedOptionalEntries() throws {
    let network = try ArcaneJSON.makeDecoder().decode(
      NetworkInspect.self,
      from: Data(
        #"{"id":"network","name":"frontend","driver":"overlay","scope":"swarm","created":"2026-08-07T00:00:00Z","enableIPv4":true,"enableIPv6":false,"ipam":{"driver":"default"},"internal":false,"attachable":true,"ingress":false,"configOnly":false,"containers":{},"options":{},"labels":{},"peers":[{"Name":"manager","IP":"10.0.0.2"},{"Name":"missing-address"},"invalid"],"services":{"api":{"VIP":"10.0.0.10","Ports":["443/tcp",42]},"worker":{},"invalid":"value"},"containersList":[]}"#
          .utf8
      )
    )

    XCTAssertEqual(network.peerList, [NetworkPeer(name: "manager", address: "10.0.0.2")])
    XCTAssertEqual(
      network.serviceList,
      [
        NetworkServiceAttachment(name: "api", vip: "10.0.0.10", ports: ["443/tcp"]),
        NetworkServiceAttachment(name: "worker"),
      ]
    )
  }

  func testTypedNetworkAccessorsTreatAbsentFieldsAsEmpty() throws {
    let network = try ArcaneJSON.makeDecoder().decode(
      NetworkInspect.self,
      from: Data(
        #"{"id":"network","name":"bridge","driver":"bridge","scope":"local","created":"2026-08-07T00:00:00Z","enableIPv4":true,"enableIPv6":false,"ipam":{"driver":"default"},"internal":false,"attachable":false,"ingress":false,"configOnly":false,"containers":{},"options":{},"labels":{},"containersList":[]}"#
          .utf8
      )
    )

    XCTAssertEqual(network.peerList, [])
    XCTAssertEqual(network.serviceList, [])
  }

  private func makeClient() -> ArcaneClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return ArcaneClient(
      configuration: .init(
        baseURL: URL(string: "https://arcane.example.com/api")!,
        urlSession: URLSession(configuration: configuration)
      )
    )
  }
}

private func response(for request: URLRequest, body: String) throws -> (HTTPURLResponse, Data) {
  let response = try XCTUnwrap(
    HTTPURLResponse(
      url: XCTUnwrap(request.url),
      statusCode: 200,
      httpVersion: nil,
      headerFields: ["Content-Type": "application/json"]
    )
  )
  return (response, Data(body.utf8))
}
