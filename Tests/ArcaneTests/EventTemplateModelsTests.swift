import Foundation
import XCTest

@testable import Arcane

final class EventTemplateModelsTests: XCTestCase {
  func testDecodeEventSeverityCountsAndDeletePermission() throws {
    let counts = try ArcaneJSON.makeDecoder().decode(
      EventSeverityCounts.self,
      from: Data(#"{"total":15,"info":4,"success":5,"warning":3,"error":3}"#.utf8)
    )

    XCTAssertEqual(counts.total, 15)
    XCTAssertEqual(counts.info, 4)
    XCTAssertEqual(counts.success, 5)
    XCTAssertEqual(counts.warning, 3)
    XCTAssertEqual(counts.error, 3)
    XCTAssertEqual(Permission.Events.delete, "events:delete")
  }

  func testTemplateSourceFilterMapsToExistingTypeQuery() async throws {
    await MockURLProtocol.reset()
    let client = makeMockClient()

    await MockURLProtocol.setHandler { request in
      let components = try XCTUnwrap(URLComponents(url: XCTUnwrap(request.url), resolvingAgainstBaseURL: false))
      let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })
      XCTAssertEqual(query["type"], "true")
      XCTAssertEqual(query["start"], "0")
      XCTAssertEqual(query["limit"], "20")
      let response = try XCTUnwrap(
        HTTPURLResponse(
          url: XCTUnwrap(request.url),
          statusCode: 200,
          httpVersion: nil,
          headerFields: ["Content-Type": "application/json"]
        )
      )
      let body = Data(
        #"{"success":true,"data":[],"pagination":{"totalPages":0,"totalItems":0,"currentPage":1,"itemsPerPage":20}}"#
          .utf8
      )
      return (response, body)
    }

    let response = try await client.templates.listPaginated(source: .remote)
    XCTAssertTrue(response.data.isEmpty)
  }

  func testEventStatsEndpointUsesExactPath() async throws {
    await MockURLProtocol.reset()
    let client = makeMockClient()

    await MockURLProtocol.setHandler { request in
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.url?.path, "/api/events/stats")
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
        #"{"success":true,"data":{"total":15,"info":4,"success":5,"warning":3,"error":3}}"#
          .utf8
      )
      return (response, body)
    }

    let counts = try await client.events.stats()
    XCTAssertEqual(counts.total, 15)
    XCTAssertEqual(counts.error, 3)
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
