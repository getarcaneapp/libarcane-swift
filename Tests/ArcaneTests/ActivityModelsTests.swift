import Foundation
import XCTest

@testable import Arcane

final class ActivityModelsTests: XCTestCase {
  private let decoder = ArcaneJSON.makeDecoder()

  func testServerCapabilitiesExposeActivitiesOnlyForV2() {
    XCTAssertFalse(ServerCapabilities(mode: .legacyRoles).supportsActivities)
    XCTAssertTrue(ServerCapabilities(mode: .rbac).supportsActivities)
  }

  func testDecodeActivityDetailAndStreamEvent() throws {
    let detailJSON = #"""
      {
              "activity": {
                  "id": "act_1",
                  "environmentId": "env_1",
                  "batchId": "bulk_deploy_1",
              "sourceEnvironmentId": "edge_1",
              "sourceEnvironmentName": "Edge Node",
              "type": "project_deploy",
              "status": "running",
              "resourceType": "project",
              "resourceId": "proj_1",
              "resourceName": "homepage",
              "progress": 65,
              "step": "Pulling images",
              "latestMessage": "Pulling nginx:latest",
              "startedBy": {
                  "userId": "u_1",
                  "username": "admin",
                  "displayName": "Admin"
              },
              "startedAt": "2026-06-01T15:00:00Z",
              "metadata": { "project": "homepage" },
              "createdAt": "2026-06-01T15:00:00Z",
              "updatedAt": "2026-06-01T15:00:10Z"
          },
          "messages": [
              {
                  "id": "msg_1",
                  "activityId": "act_1",
                  "level": "info",
                  "message": "Pulling nginx:latest",
                  "payload": { "image": "nginx:latest" },
                  "createdAt": "2026-06-01T15:00:05Z"
              }
          ]
      }
      """#

    let detail = try decoder.decode(ActivityDetail.self, from: Data(detailJSON.utf8))
    XCTAssertEqual(detail.activity.id, "act_1")
    XCTAssertEqual(detail.activity.batchID, "bulk_deploy_1")
    XCTAssertEqual(detail.activity.status, .running)
    XCTAssertEqual(detail.activity.type, .projectDeploy)
    XCTAssertEqual(detail.activity.sourceEnvironmentName, "Edge Node")
    XCTAssertEqual(detail.activity.startedBy?.displayName, "Admin")
    XCTAssertEqual(detail.messages.first?.level, .info)
    XCTAssertEqual(detail.messages.first?.payload?["image"]?.stringValue, "nginx:latest")

    let streamJSON = #"""
      {
          "type": "message",
          "activityId": "act_1",
          "message": {
              "id": "msg_2",
              "activityId": "act_1",
              "level": "success",
              "message": "Done",
              "createdAt": "2026-06-01T15:01:00Z"
          },
          "timestamp": "2026-06-01T15:01:00Z"
      }
      """#
    let event = try decoder.decode(ActivityStreamEvent.self, from: Data(streamJSON.utf8))
    XCTAssertEqual(event.type, .message)
    XCTAssertEqual(event.activityID, "act_1")
    XCTAssertEqual(event.message?.level, .success)
  }

  func testDecodeMessageResponseActivityID() throws {
    let response = try decoder.decode(
      MessageResponse.self,
      from: Data(#"{"message":"queued","activityId":"act_2"}"#.utf8)
    )

    XCTAssertEqual(response.message, "queued")
    XCTAssertEqual(response.activityID, "act_2")
  }

  func testDecodeAggregateActivityStreamVariants() throws {
    let error = try decoder.decode(
      ActivityStreamEvent.self,
      from: Data(
        #"{"type":"error","environmentId":"edge-1","error":"offline","timestamp":"2026-06-01T15:01:00Z"}"#
          .utf8
      )
    )
    XCTAssertEqual(error.type, .error)
    XCTAssertEqual(error.environmentID, "edge-1")
    XCTAssertEqual(error.error, "offline")

    let heartbeat = try decoder.decode(
      ActivityStreamEvent.self,
      from: Data(
        #"{"type":"heartbeat","timestamp":"2026-06-01T15:01:00Z"}"#.utf8
      )
    )
    XCTAssertEqual(heartbeat.type, .heartbeat)
    XCTAssertNil(heartbeat.environmentID)
  }

  func testActivitiesStreamUsesGlobalEndpoint() async throws {
    await MockURLProtocol.reset()
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    let client = ArcaneClient(
      configuration: .init(
        baseURL: URL(string: "https://arcane.example.com/base")!,
        urlSession: URLSession(configuration: configuration)
      )
    )

    await MockURLProtocol.setHandler { request in
      XCTAssertEqual(request.url?.path, "/base/api/activities/stream")
      XCTAssertEqual(request.url?.query, "limit=17")
      let response = try XCTUnwrap(
        HTTPURLResponse(
          url: XCTUnwrap(request.url),
          statusCode: 200,
          httpVersion: nil,
          headerFields: ["Content-Type": "application/x-ndjson"]
        )
      )
      let body = Data("{\"type\":\"heartbeat\",\"timestamp\":\"2026-06-01T15:01:00Z\"}\n".utf8)
      return (response, body)
    }

    var iterator = client.activities.stream(limit: 17).makeAsyncIterator()
    let event = try await iterator.next()
    XCTAssertEqual(event?.type, .heartbeat)
  }
}
