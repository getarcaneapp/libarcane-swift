import Foundation
import XCTest

@testable import Arcane

final class ActivityBackedServiceTests: XCTestCase {
  func testProjectAndContainerServicesPreserveActivityIDs() async throws {
    let client = await makeClient()

    let createdProject = try await client.projects.create(
      request: CreateProject(name: "project", composeContent: "services: {}")
    )
    let updatedProject = try await client.projects.update(
      projectID: "project",
      request: UpdateProject(name: "renamed")
    )
    let container = try await client.containers.redeploy(id: "container")
    let bulkResult = try await client.system.startAllContainers()
    let requestCount = await MockURLProtocol.requestCount()

    XCTAssertEqual(createdProject.activityID, "activity-project-create")
    XCTAssertEqual(updatedProject.activityID, "activity-project-update")
    XCTAssertEqual(container.activityID, "activity-container")
    XCTAssertEqual(bulkResult.activityID, "activity-bulk")
    XCTAssertEqual(requestCount, 4)
  }

  func testNetworkAndVolumeServicesPreserveActivityIDs() async throws {
    let client = await makeClient()

    let network = try await client.networks.create(
      request: NetworkCreateRequest(name: "network")
    )
    let networkPrune = try await client.networks.prune()
    let volume = try await client.volumes.create(request: CreateVolume(name: "volume"))
    let volumePrune = try await client.volumes.prune()
    let backup = try await client.volumes.createBackup(name: "volume")
    let requestCount = await MockURLProtocol.requestCount()

    XCTAssertEqual(network.activityID, "activity-network")
    XCTAssertEqual(networkPrune.activityID, "activity-network-prune")
    XCTAssertEqual(volume.activityID, "activity-volume")
    XCTAssertEqual(volumePrune.activityID, "activity-volume-prune")
    XCTAssertEqual(backup.activityID, "activity-backup")
    XCTAssertEqual(requestCount, 5)
  }

  func testUpdaterPruneImageAndScanServicesPreserveActivityIDs() async throws {
    let client = await makeClient()

    let updater = try await client.updater.updateContainer("container")
    let prune = try await client.system.prune(PruneAllRequest())
    let imageUpdate = try await client.images.checkUpdateByRef(imageRef: "alpine:latest")
    let scan = try await client.vulnerabilities.scanImage(imageId: "sha256:1")
    let requestCount = await MockURLProtocol.requestCount()

    XCTAssertEqual(updater.activityID, "activity-updater")
    XCTAssertEqual(prune.activityID, "activity-prune")
    XCTAssertEqual(imageUpdate.activityID, "activity-image-update")
    XCTAssertEqual(scan.activityID, "activity-scan")
    XCTAssertEqual(requestCount, 4)
  }

  private func makeClient() async -> ArcaneClient {
    await MockURLProtocol.reset()
    await MockURLProtocol.setHandler { request in
      try ActivityBackedServiceFixtures.response(for: request)
    }

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

private enum ActivityBackedServiceFixtures {
  static func response(for request: URLRequest) throws -> (HTTPURLResponse, Data) {
    guard let url = request.url else {
      throw URLError(.badURL)
    }
    let payload = try payload(for: url.path, method: request.httpMethod)
    guard let response = HTTPURLResponse(
      url: url,
      statusCode: 200,
      httpVersion: nil,
      headerFields: ["Content-Type": "application/json"]
    ) else {
      throw URLError(.badServerResponse)
    }
    return (response, Data(#"{"success":true,"data":\#(payload)}"#.utf8))
  }

  private static func payload(for path: String, method: String?) throws -> String {
    guard
      let fixture = fixtures.first(where: {
        $0.method == method && path.hasSuffix($0.pathSuffix)
      })
    else {
      throw URLError(.unsupportedURL)
    }
    return fixture.payload
  }

  private static func projectPayload(activityID: String) -> String {
    """
    {
      "id":"project","name":"project","path":"/project","status":"running",
      "serviceCount":1,"runningCount":1,"isArchived":false,
      "createdAt":"2026-07-24T12:00:00Z","updatedAt":"2026-07-24T12:00:00Z",
      "activityId":"\(activityID)"
    }
    """
  }

  private static let containerPayload = #"""
    {
      "id":"container","name":"web","image":"nginx","imageId":"sha256:1","created":"",
      "state":{"status":"running","running":true},"config":{},"hostConfig":{},
      "networkSettings":{},"ports":[],"mounts":[],"activityId":"activity-container"
    }
    """#

  private static let backupPayload = #"""
    {
      "id":"backup","volumeName":"volume","size":0,
      "createdAt":"2026-07-24T12:00:00Z","activityId":"activity-backup"
    }
    """#

  private static let updaterPayload = #"""
    {
      "checked":1,"updated":1,"skipped":0,"failed":0,"duration":"1s",
      "items":[],"activityId":"activity-updater"
    }
    """#

  private static let imageUpdatePayload = #"""
    {
      "hasUpdate":false,"updateType":"digest","currentVersion":"latest",
      "responseTimeMs":1,"activityId":"activity-image-update"
    }
    """#

  private static let scanPayload = #"""
    {
      "imageId":"sha256:1","imageName":"alpine",
      "scanTime":"2026-07-24T12:00:00Z","status":"completed",
      "activityId":"activity-scan"
    }
    """#

  private static let fixtures: [Fixture] = [
    Fixture(
      method: "POST",
      pathSuffix: "/projects",
      payload: projectPayload(activityID: "activity-project-create")
    ),
    Fixture(
      method: "PUT",
      pathSuffix: "/projects/project",
      payload: projectPayload(activityID: "activity-project-update")
    ),
    Fixture(
      method: "POST",
      pathSuffix: "/containers/container/redeploy",
      payload: containerPayload
    ),
    Fixture(
      method: "POST",
      pathSuffix: "/system/containers/start-all",
      payload: #"{"success":true,"activityId":"activity-bulk"}"#
    ),
    Fixture(
      method: "POST",
      pathSuffix: "/networks/prune",
      payload:
        #"{"networksDeleted":[],"spaceReclaimed":0,"activityId":"activity-network-prune"}"#
    ),
    Fixture(
      method: "POST",
      pathSuffix: "/networks",
      payload: #"{"id":"network","activityId":"activity-network"}"#
    ),
    Fixture(
      method: "POST",
      pathSuffix: "/volumes/prune",
      payload:
        #"{"volumesDeleted":[],"spaceReclaimed":0,"activityId":"activity-volume-prune"}"#
    ),
    Fixture(
      method: "POST",
      pathSuffix: "/volumes/volume/backups",
      payload: backupPayload
    ),
    Fixture(
      method: "POST",
      pathSuffix: "/volumes",
      payload: #"{"id":"volume","activityId":"activity-volume"}"#
    ),
    Fixture(
      method: "POST",
      pathSuffix: "/containers/container/update",
      payload: updaterPayload
    ),
    Fixture(
      method: "POST",
      pathSuffix: "/system/prune",
      payload: #"{"spaceReclaimed":0,"success":true,"activityId":"activity-prune"}"#
    ),
    Fixture(
      method: "GET",
      pathSuffix: "/image-updates/check",
      payload: imageUpdatePayload
    ),
    Fixture(
      method: "POST",
      pathSuffix: "/vulnerabilities/scan",
      payload: scanPayload
    )
  ]

  private struct Fixture {
    let method: String
    let pathSuffix: String
    let payload: String
  }
}
