import Foundation
import XCTest

@testable import Arcane

final class DashboardStreamModelsTests: XCTestCase {
  private let decoder = ArcaneJSON.makeDecoder()

  func testDecodeHeartbeatEvent() throws {
    let json = #"{"type":"heartbeat","timestamp":"2026-06-10T17:00:00.123Z"}"#

    let event = try decoder.decode(DashboardStreamEvent.self, from: Data(json.utf8))
    XCTAssertEqual(event.type, .heartbeat)
    XCTAssertNil(event.environmentID)
    XCTAssertEqual(event.resolvedEnvironmentID, EnvironmentID.localDocker.rawValue)
    XCTAssertNil(event.snapshot)
  }

  func testDecodeSnapshotEventWithNullTables() throws {
    // Stream snapshots trim containers.data / images.data to JSON null;
    // only the aggregate counts and metadata are populated.
    let json = #"""
      {
          "type": "snapshot",
          "environmentId": "0",
          "snapshot": {
              "containers": {
                  "data": null,
                  "counts": {
                      "runningContainers": 7,
                      "stoppedContainers": 2,
                      "totalContainers": 9
                  },
                  "pagination": {
                      "totalPages": 1,
                      "totalItems": 9,
                      "currentPage": 1,
                      "itemsPerPage": 10
                  }
              },
              "images": {
                  "data": null,
                  "pagination": {
                      "totalPages": 1,
                      "totalItems": 14,
                      "currentPage": 1,
                      "itemsPerPage": 10
                  }
              },
              "imageUsageCounts": {
                  "imagesInuse": 9,
                  "imagesUnused": 5,
                  "totalImages": 14,
                  "totalImageSize": 4815162342
              },
              "actionItems": {
                  "items": [
                      { "kind": "stopped_containers", "count": 2, "severity": "warning" },
                      { "kind": "image_updates", "count": 3, "severity": "warning" },
                      { "kind": "future_kind", "count": 1, "severity": "catastrophic" }
                  ]
              },
              "settings": {},
              "versionInfo": {
                  "currentVersion": "2.0.2",
                  "revision": "28a441461051a7101708ab697b61c7eb50ce988b",
                  "shortRevision": "28a4414",
                  "goVersion": "go1.24.0",
                  "nodeVersion": "22.0.0",
                  "svelteKitVersion": "2.0.0",
                  "displayVersion": "2.0.2",
                  "isSemverVersion": true,
                  "newestVersion": "2.1.0",
                  "updateAvailable": true
              }
          },
          "timestamp": "2026-06-10T17:00:00Z"
      }
      """#

    let event = try decoder.decode(DashboardStreamEvent.self, from: Data(json.utf8))
    XCTAssertEqual(event.type, .snapshot)
    XCTAssertEqual(event.environmentID, "0")
    XCTAssertEqual(event.resolvedEnvironmentID, "0")

    let snapshot = try XCTUnwrap(event.snapshot)
    XCTAssertEqual(snapshot.containers.data, [])
    XCTAssertEqual(snapshot.containers.counts.runningContainers, 7)
    XCTAssertEqual(snapshot.containers.counts.stoppedContainers, 2)
    XCTAssertEqual(snapshot.containers.counts.totalContainers, 9)
    XCTAssertEqual(snapshot.images.data, [])
    XCTAssertEqual(snapshot.imageUsageCounts.totalImages, 14)
    XCTAssertEqual(snapshot.imageUsageCounts.totalImageSize, 4_815_162_342)
    XCTAssertEqual(snapshot.actionItems.items.count, 3)
    XCTAssertEqual(snapshot.actionItems.items.first?.kind, .stoppedContainers)
    XCTAssertEqual(snapshot.actionItems.items.last?.kind, .unknown("future_kind"))
    XCTAssertEqual(snapshot.actionItems.items.last?.severity, .unknown("catastrophic"))
    XCTAssertEqual(snapshot.versionInfo?.updateAvailable, true)
    XCTAssertEqual(snapshot.versionInfo?.newestVersion, "2.1.0")
  }

  func testDecodeErrorEvents() throws {
    let incompatible =
      #"{"type":"error","environmentId":"env_9","error":"agent dashboard endpoint missing","#
      + #""errorCode":"agent_incompatible","timestamp":"2026-06-10T17:00:00Z"}"#
    let event = try decoder.decode(DashboardStreamEvent.self, from: Data(incompatible.utf8))
    XCTAssertEqual(event.type, .error)
    XCTAssertEqual(event.environmentID, "env_9")
    XCTAssertEqual(event.errorCode, .agentIncompatible)
    XCTAssertEqual(event.error, "agent dashboard endpoint missing")

    let futureCode = #"""
      {"type":"error","environmentId":"env_9","error":"boom","errorCode":"weird_new_code","timestamp":"2026-06-10T17:00:00Z"}
      """#
    let unknownEvent = try decoder.decode(DashboardStreamEvent.self, from: Data(futureCode.utf8))
    XCTAssertEqual(unknownEvent.errorCode, .unknown("weird_new_code"))

    let unclassified = #"""
      {"type":"error","environmentId":"env_9","error":"boom","timestamp":"2026-06-10T17:00:00Z"}
      """#
    let unclassifiedEvent = try decoder.decode(
      DashboardStreamEvent.self, from: Data(unclassified.utf8))
    XCTAssertNil(unclassifiedEvent.errorCode)
  }

  func testUnknownEventTypeIsTolerated() throws {
    let json = #"{"type":"future_thing","timestamp":"2026-06-10T17:00:00Z"}"#

    let event = try decoder.decode(DashboardStreamEvent.self, from: Data(json.utf8))
    XCTAssertEqual(event.type, .unknown("future_thing"))
  }

  func testRESTSnapshotWithPopulatedTablesStillDecodes() throws {
    // Regression guard for the custom inits: the per-environment REST
    // snapshot still carries full table rows.
    let json = #"""
      {
          "containers": {
              "data": [
                  {
                      "id": "abc123",
                      "names": ["web"],
                      "image": "nginx:latest",
                      "imageId": "sha256:def",
                      "command": "nginx -g 'daemon off;'",
                      "created": 1760000000,
                      "ports": [],
                      "labels": {},
                      "state": "running",
                      "status": "Up 2 hours",
                      "hostConfig": {},
                      "networkSettings": { "networks": {} },
                      "mounts": []
                  }
              ],
              "counts": { "runningContainers": 1, "stoppedContainers": 0, "totalContainers": 1 },
              "pagination": { "totalPages": 1, "totalItems": 1, "currentPage": 1, "itemsPerPage": 10 }
          },
          "images": {
              "data": [ { "id": "sha256:def", "repo": "nginx", "tag": "latest" } ],
              "pagination": { "totalPages": 1, "totalItems": 1, "currentPage": 1, "itemsPerPage": 10 }
          },
          "imageUsageCounts": { "imagesInuse": 1, "imagesUnused": 0, "totalImages": 1, "totalImageSize": 100 },
          "actionItems": { "items": [] },
          "settings": {}
      }
      """#

    let snapshot = try decoder.decode(DashboardSnapshot.self, from: Data(json.utf8))
    XCTAssertEqual(snapshot.containers.data.count, 1)
    XCTAssertEqual(snapshot.containers.data.first?.id, "abc123")
    XCTAssertEqual(snapshot.images.data.count, 1)
    XCTAssertNil(snapshot.versionInfo)
  }

  func testEnvironmentDecodesLastEdgeTransport() throws {
    let json = #"""
      {
          "id": "env_1",
          "name": "Edge Node",
          "apiUrl": "https://edge.example.com",
          "status": "online",
          "enabled": true,
          "isEdge": true,
          "lastEdgeTransport": "grpc"
      }
      """#

    let environment = try decoder.decode(Arcane.Environment.self, from: Data(json.utf8))
    XCTAssertEqual(environment.lastEdgeTransport, "grpc")
  }
}
