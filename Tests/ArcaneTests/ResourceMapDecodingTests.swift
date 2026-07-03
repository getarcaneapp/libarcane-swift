import Foundation
import XCTest

@testable import Arcane

final class ResourceMapDecodingTests: XCTestCase {
  private let decoder = ArcaneJSON.makeDecoder()

  func testContainerSummaryDecodesNullLabelsAsEmptyDictionary() throws {
    let json = #"""
      {
          "id": "container-id",
          "names": ["/app"],
          "image": "example/app:latest",
          "imageId": "sha256:image",
          "command": "",
          "created": 0,
          "ports": [],
          "labels": null,
          "state": "running",
          "status": "Up",
          "hostConfig": {},
          "networkSettings": { "networks": {} },
          "mounts": []
      }
      """#

    let container = try decoder.decode(ContainerSummary.self, from: Data(json.utf8))

    XCTAssertEqual(container.labels, [:])
  }

  func testContainerSummaryDecodesThemedIconUrls() throws {
    let json = #"""
      {
          "id": "container-id",
          "names": ["/app"],
          "image": "example/app:latest",
          "imageId": "sha256:image",
          "command": "",
          "created": 0,
          "ports": [],
          "labels": {},
          "state": "running",
          "status": "Up",
          "hostConfig": {},
          "networkSettings": { "networks": {} },
          "mounts": [],
          "iconLightUrl": "https://cdn.example/app-light.png",
          "iconDarkUrl": "https://cdn.example/app-dark.png"
      }
      """#

    let container = try decoder.decode(ContainerSummary.self, from: Data(json.utf8))

    XCTAssertEqual(container.iconLightUrl, "https://cdn.example/app-light.png")
    XCTAssertEqual(container.iconDarkUrl, "https://cdn.example/app-dark.png")
  }

  func testContainerDetailsDecodesThemedIconUrls() throws {
    let json = #"""
      {
          "id": "container-id",
          "name": "/app",
          "image": "example/app:latest",
          "imageId": "sha256:image",
          "created": "2026-06-06T00:00:00Z",
          "state": { "status": "running", "running": true },
          "config": {},
          "hostConfig": {},
          "networkSettings": { "networks": {} },
          "ports": [],
          "mounts": [],
          "labels": {},
          "iconLightUrl": "https://cdn.example/detail-light.png",
          "iconDarkUrl": "https://cdn.example/detail-dark.png"
      }
      """#

    let container = try decoder.decode(ContainerDetails.self, from: Data(json.utf8))

    XCTAssertEqual(container.iconLightUrl, "https://cdn.example/detail-light.png")
    XCTAssertEqual(container.iconDarkUrl, "https://cdn.example/detail-dark.png")
  }

  func testProjectDetailsDecodesThemedIconUrls() throws {
    let json = #"""
      {
          "id": "project-id",
          "name": "Project",
          "path": "/srv/projects/project",
          "status": "running",
          "serviceCount": 1,
          "runningCount": 1,
          "isArchived": false,
          "createdAt": "2026-06-06T00:00:00Z",
          "updatedAt": "2026-06-06T00:00:00Z",
          "iconLightUrl": "https://cdn.example/project-light.png",
          "iconDarkUrl": "https://cdn.example/project-dark.png"
      }
      """#

    let project = try decoder.decode(ProjectDetails.self, from: Data(json.utf8))

    XCTAssertEqual(project.iconLightUrl, "https://cdn.example/project-light.png")
    XCTAssertEqual(project.iconDarkUrl, "https://cdn.example/project-dark.png")
  }

  func testRuntimeServiceDecodesThemedIconUrls() throws {
    let json = #"""
      {
          "name": "app",
          "image": "example/app:latest",
          "status": "running",
          "iconLightUrl": "https://cdn.example/service-light.png",
          "iconDarkUrl": "https://cdn.example/service-dark.png"
      }
      """#

    let service = try decoder.decode(RuntimeService.self, from: Data(json.utf8))

    XCTAssertEqual(service.iconLightUrl, "https://cdn.example/service-light.png")
    XCTAssertEqual(service.iconDarkUrl, "https://cdn.example/service-dark.png")
  }

  func testContainerNetworkSettingsDecodesNullNetworksAsEmptyDictionary() throws {
    let settings = try decoder.decode(
      ContainerNetworkSettings.self, from: Data(#"{"networks":null}"#.utf8))

    XCTAssertEqual(settings.networks, [:])
  }

  func testImageSummaryDecodesNullLabelsAsEmptyDictionary() throws {
    let json = #"""
      {
          "id": "sha256:image",
          "repoTags": ["example/app:latest"],
          "repoDigests": [],
          "created": 0,
          "size": 0,
          "virtualSize": 0,
          "labels": null,
          "inUse": false,
          "repo": "example/app",
          "tag": "latest"
      }
      """#

    let image = try decoder.decode(ImageSummary.self, from: Data(json.utf8))

    XCTAssertEqual(image.labels, [:])
  }

  func testNetworkSummaryDecodesNullMapsAsEmptyDictionaries() throws {
    let json = #"""
      {
          "id": "network-id",
          "name": "bridge",
          "driver": "bridge",
          "scope": "local",
          "created": "2026-06-01T00:00:00Z",
          "options": null,
          "labels": null,
          "inUse": false,
          "isDefault": true
      }
      """#

    let network = try decoder.decode(NetworkSummary.self, from: Data(json.utf8))

    XCTAssertEqual(network.options, [:])
    XCTAssertEqual(network.labels, [:])
  }

  func testNetworkInspectDecodesNullMapsAsEmptyDictionaries() throws {
    let json = #"""
      {
          "id": "network-id",
          "name": "bridge",
          "driver": "bridge",
          "scope": "local",
          "created": "2026-06-01T00:00:00Z",
          "enableIPv4": true,
          "enableIPv6": false,
          "ipam": {},
          "internal": false,
          "attachable": false,
          "ingress": false,
          "configOnly": false,
          "containers": null,
          "options": null,
          "labels": null,
          "containersList": []
      }
      """#

    let network = try decoder.decode(NetworkInspect.self, from: Data(json.utf8))

    XCTAssertEqual(network.containers, [:])
    XCTAssertEqual(network.options, [:])
    XCTAssertEqual(network.labels, [:])
  }

  func testVolumeDecodesNullMapsAsEmptyDictionaries() throws {
    let json = #"""
      {
          "id": "volume-name",
          "name": "volume-name",
          "driver": "local",
          "mountpoint": "/var/lib/docker/volumes/volume-name/_data",
          "scope": "local",
          "options": null,
          "labels": null,
          "createdAt": "2026-06-01T00:00:00Z",
          "inUse": false,
          "size": 0,
          "containers": []
      }
      """#

    let volume = try decoder.decode(Volume.self, from: Data(json.utf8))

    XCTAssertEqual(volume.options, [:])
    XCTAssertEqual(volume.labels, [:])
  }
}
