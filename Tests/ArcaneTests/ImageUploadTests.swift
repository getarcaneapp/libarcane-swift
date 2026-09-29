import Foundation
import XCTest

@testable import Arcane

final class ImageUploadTests: XCTestCase {
  private let mock = MockURLProtocolSession()
  func testUploadUsesFilePartAndReturnsServerResult() async throws {
    await mock.reset()
    let client = makeClient()
    await mock.setHandler { request in
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(request.url?.path, "/api/environments/0/images/upload")
      let body = try mockRequestBody(request)
      let bodyText = try XCTUnwrap(String(data: body, encoding: .utf8))
      XCTAssertTrue(bodyText.contains(#"name="file"; filename="image.tar""#))

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
        Data(#"{"success":true,"data":{"stream":"Loaded image: example:test\n"}}"#.utf8)
      )
    }

    let uploadURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
    try Data("image archive".utf8).write(to: uploadURL)
    defer { try? FileManager.default.removeItem(at: uploadURL) }

    let result = try await client.images.upload(
      fileURL: uploadURL,
      filename: "image.tar"
    )

    XCTAssertEqual(result.stream, "Loaded image: example:test\n")
  }

  private func makeClient() -> ArcaneClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return ArcaneClient(
      configuration: .init(
        baseURL: URL(string: "https://arcane.example.com")!,
        urlSession: mock.session(configuration: configuration)
      )
    )
  }
}
