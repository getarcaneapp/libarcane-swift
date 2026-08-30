import Foundation
import XCTest

@testable import Arcane

final class MobilePushTests: XCTestCase {
  func testCapabilityFlagFromEnabledFeatures() {
    XCTAssertFalse(ServerCapabilities(mode: .rbac).supportsMobilePush)
    XCTAssertTrue(ServerCapabilities(mode: .rbac, enabledFeatures: ["mobile-push-v1"]).supportsMobilePush)
  }

  func testStatusDecodesAndPayloadParsesFromUserInfo() async throws {
    await MockURLProtocol.reset()
    await MockURLProtocol.setHandler { request in
      XCTAssertEqual(request.url?.path, "/api/apns/status")
      let body = """
        {"success":true,"data":{"enabled":true,"channelId":"ch_1","relayUrl":"https://apns.getarcane.app",
        "devices":[{"id":"d1","label":"iPhone","events":{"image_update":true},"environmentIds":[],"createdAt":"2026-08-29T18:00:00Z"}]}}
        """
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "application/json"])!
      return (response, Data(body.utf8))
    }
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    let client = ArcaneClient(
      configuration: .init(
        baseURL: URL(string: "https://arcane.example.com")!,
        urlSession: URLSession(configuration: configuration)))

    let status = try await client.mobilePush.status()
    XCTAssertTrue(status.enabled)
    XCTAssertEqual(status.devices.first?.id, "d1")
    XCTAssertTrue(status.devices.first!.isEnabled(.imageUpdate))

    let userInfo: [AnyHashable: Any] = [
      "aps": ["alert": ["title": "t"]],
      "arcane": [
        "v": 1, "eventId": "e1", "occurredAt": "2026-08-29T18:00:00Z", "type": "auto_heal",
        "severity": "warning", "environmentId": "0",
        "route": ["kind": "container", "environmentId": "0", "id": "abc"], "channelId": "ch_1",
      ],
    ]
    let payload = try XCTUnwrap(MobilePushPayload(userInfo: userInfo))
    XCTAssertEqual(payload.route.kind, .container)
    XCTAssertEqual(payload.route.id, "abc")
    XCTAssertNil(MobilePushPayload(userInfo: ["aps": [:]]))
  }
}
