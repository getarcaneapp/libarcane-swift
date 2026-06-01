@testable import Arcane
import Foundation
import XCTest

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

    func testContainerNetworkSettingsDecodesNullNetworksAsEmptyDictionary() throws {
        let settings = try decoder.decode(ContainerNetworkSettings.self, from: Data(#"{"networks":null}"#.utf8))

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
