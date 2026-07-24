import Foundation
import XCTest

@testable import Arcane

final class ActivityBackedResponseTests: XCTestCase {
  private let decoder = ArcaneJSON.makeDecoder()

  func testProjectContainerAndNetworkResponsesDecodeActivityID() throws {
    let projectCreate = try decode(
      ProjectCreateResponse.self,
      #"""
      {
        "id": "p", "name": "project", "path": "/project", "status": "running",
        "serviceCount": 1, "runningCount": 1, "isArchived": false,
        "createdAt": "2026-07-24T12:00:00Z", "updatedAt": "2026-07-24T12:00:00Z",
        "activityId": "a-project-create"
      }
      """#
    )
    XCTAssertEqual(projectCreate.activityID, "a-project-create")

    let projectDetails = try decode(
      ProjectDetails.self,
      #"""
      {
        "id": "p", "name": "project", "path": "/project", "status": "running",
        "serviceCount": 1, "runningCount": 1, "isArchived": false,
        "createdAt": "2026-07-24T12:00:00Z", "updatedAt": "2026-07-24T12:00:00Z",
        "activityId": "a-project"
      }
      """#
    )
    XCTAssertEqual(projectDetails.activityID, "a-project")

    let container = try decode(
      ContainerDetails.self,
      #"""
      {
        "id": "c", "name": "web", "image": "nginx", "imageId": "sha256:1", "created": "",
        "state": {"status": "running", "running": true}, "config": {}, "hostConfig": {},
        "networkSettings": {}, "ports": [], "mounts": [], "activityId": "a-container"
      }
      """#
    )
    XCTAssertEqual(container.activityID, "a-container")

    let containerAction = try decode(
      ContainerActionResult.self,
      #"{"success":true,"activityId":"a-container-action"}"#
    )
    XCTAssertEqual(containerAction.activityID, "a-container-action")

    let systemContainerAction = try decode(
      SystemContainerActionResult.self,
      #"{"success":true,"activityId":"a-system-container"}"#
    )
    XCTAssertEqual(systemContainerAction.activityID, "a-system-container")

    let networkCreate = try decode(
      NetworkCreateResponse.self,
      #"{"id":"n","activityId":"a-network-create"}"#
    )
    XCTAssertEqual(networkCreate.activityID, "a-network-create")

    let networkPrune = try decode(
      NetworkPruneReport.self,
      #"{"networksDeleted":[],"spaceReclaimed":0,"activityId":"a-network-prune"}"#
    )
    XCTAssertEqual(networkPrune.activityID, "a-network-prune")
  }

  func testVolumeUpdaterSystemImageAndScanResponsesDecodeActivityID() throws {
    let volume = try decode(
      Volume.self,
      #"{"id":"v","activityId":"a-volume"}"#
    )
    XCTAssertEqual(volume.activityID, "a-volume")

    let volumePrune = try decode(
      VolumePruneReport.self,
      #"{"volumesDeleted":[],"spaceReclaimed":0,"activityId":"a-volume-prune"}"#
    )
    XCTAssertEqual(volumePrune.activityID, "a-volume-prune")

    let backup = try decode(
      BackupEntry.self,
      #"{"id":"b","volumeName":"v","size":0,"createdAt":"2026-07-24T12:00:00Z","activityId":"a-backup"}"#
    )
    XCTAssertEqual(backup.activityID, "a-backup")

    let updater = try decode(
      UpdaterResult.self,
      #"{"checked":1,"updated":1,"skipped":0,"failed":0,"duration":"1s","items":[],"activityId":"a-updater"}"#
    )
    XCTAssertEqual(updater.activityID, "a-updater")

    let prune = try decode(
      PruneAllResult.self,
      #"{"spaceReclaimed":0,"success":true,"activityId":"a-prune"}"#
    )
    XCTAssertEqual(prune.activityID, "a-prune")

    let vulnerability = try decode(
      VulnerabilityScanResult.self,
      #"{"imageId":"sha256:1","imageName":"alpine","scanTime":"2026-07-24T12:00:00Z","status":"completed","activityId":"a-scan"}"#
    )
    XCTAssertEqual(vulnerability.activityID, "a-scan")

    let imageUpdate = try decode(
      ImageUpdateResponse.self,
      #"{"hasUpdate":false,"updateType":"digest","currentVersion":"latest","responseTimeMs":1,"activityId":"a-image-update"}"#
    )
    XCTAssertEqual(imageUpdate.activityID, "a-image-update")
  }

  func testActivityBackedMessageMutationsReturnResponses() async throws {
    await MockURLProtocol.reset()
    let client = makeClient()
    await MockURLProtocol.setHandler { request in
      let response = try XCTUnwrap(
        HTTPURLResponse(
          url: XCTUnwrap(request.url),
          statusCode: 200,
          httpVersion: nil,
          headerFields: ["Content-Type": "application/json"]
        )
      )
      return (
        response,
        Data(
          #"{"success":true,"data":{"message":"accepted","activityId":"activity-1"}}"#.utf8
        )
      )
    }

    var responses: [MessageResponse] = []
    responses.append(try await client.projects.down(projectID: "project"))
    responses.append(try await client.projects.restart(projectID: "project"))
    responses.append(try await client.projects.destroy(projectID: "project"))
    responses.append(try await client.containers.start(id: "container"))
    responses.append(try await client.containers.stop(id: "container"))
    responses.append(try await client.containers.restart(id: "container"))
    responses.append(try await client.containers.pause(id: "container"))
    responses.append(try await client.containers.unpause(id: "container"))
    responses.append(try await client.containers.kill(id: "container"))
    responses.append(try await client.containers.delete(id: "container"))
    responses.append(try await client.networks.delete(networkID: "network"))
    responses.append(try await client.volumes.remove(name: "volume"))
    responses.append(try await client.volumes.createDirectory(name: "volume", path: "/folder"))
    responses.append(try await client.volumes.deleteFile(name: "volume", path: "/file"))
    responses.append(
      try await client.volumes.restoreBackup(
        name: "volume",
        backupID: "backup"
      )
    )
    responses.append(
      try await client.volumes.restoreBackupFiles(
        name: "volume",
        backupID: "backup",
        paths: ["/file"]
      )
    )
    responses.append(try await client.volumes.deleteBackup(backupID: "backup"))

    let uploadURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
    try Data("contents".utf8).write(to: uploadURL)
    defer { try? FileManager.default.removeItem(at: uploadURL) }
    responses.append(
      try await client.volumes.uploadFile(
        name: "volume",
        path: "/",
        fileURL: uploadURL
      )
    )

    XCTAssertEqual(responses.count, 18)
    XCTAssertTrue(responses.allSatisfy { $0.activityID == "activity-1" })
  }

  private func decode<Value: Decodable>(_ type: Value.Type, _ json: String) throws -> Value {
    try decoder.decode(type, from: Data(json.utf8))
  }

  private func makeClient() -> ArcaneClient {
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
