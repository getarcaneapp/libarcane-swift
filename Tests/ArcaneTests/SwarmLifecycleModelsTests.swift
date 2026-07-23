import Foundation
import XCTest

@testable import Arcane

final class SwarmLifecycleModelsTests: XCTestCase {
  private let decoder = ArcaneJSON.makeDecoder()
  private let encoder = ArcaneJSON.makeEncoder()

  func testOlderSwarmNodeDefaultsMissingAgentCoverage() throws {
    let node = try decoder.decode(
      SwarmNode.self,
      from: Data(
        #"{"id":"node_1","hostname":"worker-1","role":"worker","availability":"active","status":"ready","createdAt":"2026-07-20T12:00:00Z","updatedAt":"2026-07-20T12:01:00Z"}"#
          .utf8
      )
    )

    XCTAssertEqual(node.agent.state, .none)
    XCTAssertTrue(node.agent.candidates.isEmpty)
    XCTAssertNil(node.managerAddress)
  }

  func testDecodeAgentBindingCandidatesAndFutureStates() throws {
    let node = try decoder.decode(
      SwarmNode.self,
      from: Data(
        #"{"id":"node_2","hostname":"manager-1","role":"manager","availability":"active","status":"ready","managerAddress":"10.0.0.2:2377","createdAt":"2026-07-20T12:00:00Z","updatedAt":"2026-07-20T12:01:00Z","agent":{"state":"ambiguous","bindingKind":"pooled","candidates":[{"environmentId":"edge_1","environmentName":"Edge One","environmentType":"agent"}]}}"#
          .utf8
      )
    )

    XCTAssertEqual(node.managerAddress, "10.0.0.2:2377")
    XCTAssertEqual(node.agent.state, .ambiguous)
    XCTAssertEqual(node.agent.bindingKind, .unknown("pooled"))
    XCTAssertEqual(node.agent.candidates.first?.environmentID, "edge_1")

    let futureState = try decoder.decode(
      SwarmNodeAgentState.self,
      from: Data(#""draining""#.utf8)
    )
    XCTAssertEqual(futureState, .unknown("draining"))
  }

  func testReconcileResponseDefaultsOlderFields() throws {
    let response = try decoder.decode(
      SwarmNodeAgentReconcileResponse.self,
      from: Data(#"{"results":[{"nodeId":"node_1"}]}"#.utf8)
    )

    XCTAssertEqual(response.results.first?.state, SwarmNodeAgentState.none)
    XCTAssertEqual(response.results.first?.candidates, [])
  }

  func testEasyJoinContractsUseBackendFieldNames() throws {
    let request = SwarmJoinEnvironmentsRequest(
      remoteAddrs: ["10.0.0.2:2377"],
      targets: [
        .init(
          environmentID: "edge_1",
          role: .manager,
          availability: "active",
          advertiseAddr: "10.0.0.3"
        )
      ]
    )
    let data = try encoder.encode(request)
    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    let targets = try XCTUnwrap(object["targets"] as? [[String: Any]])

    XCTAssertEqual(object["remoteAddrs"] as? [String], ["10.0.0.2:2377"])
    XCTAssertEqual(targets.first?["environmentId"] as? String, "edge_1")
    XCTAssertEqual(targets.first?["role"] as? String, "manager")
    XCTAssertEqual(targets.first?["advertiseAddr"] as? String, "10.0.0.3")

    let response = try decoder.decode(
      SwarmJoinEnvironmentsResponse.self,
      from: Data(
        #"{"results":[{"environmentId":"edge_1","state":"joined","nodeId":"node_3"},{"environmentId":"edge_2","state":"waiting_for_agent"}]}"#
          .utf8
      )
    )
    XCTAssertEqual(response.results[0].state, .joined)
    XCTAssertEqual(response.results[0].nodeID, "node_3")
    XCTAssertEqual(response.results[1].state, .unknown("waiting_for_agent"))
  }

  func testBindingRequestEncodesOptionalActions() throws {
    let data = try encoder.encode(
      SwarmNodeAgentBindingRequest(
        environmentID: "edge_1",
        rebind: true,
        replaceDeployment: true
      )
    )
    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    XCTAssertEqual(object["environmentId"] as? String, "edge_1")
    XCTAssertEqual(object["rebind"] as? Bool, true)
    XCTAssertEqual(object["replaceDeployment"] as? Bool, true)
  }

  func testReconcileEndpointSendsRequiredEmptyJSONBody() async throws {
    await MockURLProtocol.reset()
    let client = makeMockClient()

    await MockURLProtocol.setHandler { request in
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(request.url?.path, "/api/environments/manager_1/swarm/nodes/agents/reconcile")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
      XCTAssertTrue(request.httpBody != nil || request.httpBodyStream != nil)
      let response = try XCTUnwrap(
        HTTPURLResponse(
          url: XCTUnwrap(request.url),
          statusCode: 200,
          httpVersion: nil,
          headerFields: ["Content-Type": "application/json"]
        )
      )
      return (response, Data(#"{"success":true,"data":{"results":[]}}"#.utf8))
    }

    let response = try await client.swarm.reconcileNodeAgents(envID: "manager_1")
    XCTAssertTrue(response.results.isEmpty)
  }

  func testJoinCandidatesEndpointUsesExactPath() async throws {
    await MockURLProtocol.reset()
    let client = makeMockClient()

    await MockURLProtocol.setHandler { request in
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.url?.path, "/api/environments/manager_1/swarm/join-candidates")
      XCTAssertNil(request.url?.query)
      let response = try XCTUnwrap(
        HTTPURLResponse(
          url: XCTUnwrap(request.url),
          statusCode: 200,
          httpVersion: nil,
          headerFields: ["Content-Type": "application/json"]
        )
      )
      let body = Data(
        #"{"success":true,"data":[{"environmentId":"edge_1","environmentName":"Edge One","environmentType":"agent","status":"online"}]}"#
          .utf8
      )
      return (response, body)
    }

    let candidates = try await client.swarm.joinCandidates(envID: "manager_1")
    XCTAssertEqual(candidates.first?.environmentID, "edge_1")
  }

  func testJoinEnvironmentsEndpointUsesExactPathBodyAndBatchHeader() async throws {
    await MockURLProtocol.reset()
    let client = makeMockClient()
    let joinRequest = SwarmJoinEnvironmentsRequest(
      remoteAddrs: ["10.0.0.2:2377"],
      targets: [
        .init(
          environmentID: "edge_1",
          role: .manager,
          availability: "active",
          listenAddr: "0.0.0.0:2377",
          advertiseAddr: "10.0.0.3:2377",
          dataPathAddr: "10.0.0.3"
        )
      ]
    )
    let options = try ArcaneRequestOptions(activityBatchID: "easy_join_1")

    await MockURLProtocol.setHandler { request in
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(request.url?.path, "/api/environments/manager_1/swarm/join-environments")
      XCTAssertNil(request.url?.query)
      XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
      XCTAssertEqual(
        request.value(forHTTPHeaderField: "X-Arcane-Batch-Id"),
        "easy_join_1"
      )
      let body = try requestBodyData(request)
      let object = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
      let targets = try XCTUnwrap(object["targets"] as? [[String: Any]])
      let target = try XCTUnwrap(targets.first)
      XCTAssertEqual(Set(object.keys), ["remoteAddrs", "targets"])
      XCTAssertEqual(
        Set(target.keys),
        ["environmentId", "role", "availability", "listenAddr", "advertiseAddr", "dataPathAddr"]
      )
      XCTAssertEqual(object["remoteAddrs"] as? [String], ["10.0.0.2:2377"])
      XCTAssertEqual(target["environmentId"] as? String, "edge_1")
      XCTAssertEqual(target["role"] as? String, "manager")
      XCTAssertEqual(target["availability"] as? String, "active")
      XCTAssertEqual(target["listenAddr"] as? String, "0.0.0.0:2377")
      XCTAssertEqual(target["advertiseAddr"] as? String, "10.0.0.3:2377")
      XCTAssertEqual(target["dataPathAddr"] as? String, "10.0.0.3")

      let response = try XCTUnwrap(
        HTTPURLResponse(
          url: XCTUnwrap(request.url),
          statusCode: 200,
          httpVersion: nil,
          headerFields: ["Content-Type": "application/json"]
        )
      )
      let responseBody = Data(
        #"{"success":true,"data":{"results":[{"environmentId":"edge_1","state":"joined","nodeId":"node_3"}]}}"#
          .utf8
      )
      return (response, responseBody)
    }

    let response = try await client.swarm.joinEnvironments(
      joinRequest,
      envID: "manager_1",
      options: options
    )
    XCTAssertEqual(response.results.first?.state, .joined)
    XCTAssertEqual(response.results.first?.nodeID, "node_3")
  }

  private func makeMockClient() -> ArcaneClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return ArcaneClient(
      configuration: .init(
        baseURL: URL(string: "https://arcane.example.com")!,
        urlSession: URLSession(configuration: configuration)
      )
    )
  }
}

private enum RequestBodyError: Error {
  case missingBody
  case streamReadFailed
}

private func requestBodyData(_ request: URLRequest) throws -> Data {
  if let body = request.httpBody { return body }
  guard let stream = request.httpBodyStream else { throw RequestBodyError.missingBody }

  stream.open()
  defer { stream.close() }
  var body = Data()
  var buffer = [UInt8](repeating: 0, count: 1_024)
  while true {
    let count = stream.read(&buffer, maxLength: buffer.count)
    guard count >= 0 else { throw RequestBodyError.streamReadFailed }
    guard count > 0 else { return body }
    body.append(buffer, count: count)
  }
}
