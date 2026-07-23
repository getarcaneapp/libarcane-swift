import Foundation
import XCTest

@testable import Arcane

final class ArcaneRequestOptionsTests: XCTestCase {
  func testActivityBatchIDValidationMatchesBackendContract() throws {
    let valid = [
      "batch_ABC-123",
      String(repeating: "a", count: 64),
    ]
    for value in valid {
      XCTAssertEqual(try ArcaneRequestOptions(activityBatchID: value).activityBatchID, value)
    }

    let invalid = [
      "",
      String(repeating: "a", count: 65),
      "contains space",
      "contains/slash",
      "batch-é",
    ]
    for value in invalid {
      XCTAssertThrowsError(try ArcaneRequestOptions(activityBatchID: value)) { error in
        XCTAssertEqual(
          error as? ArcaneRequestOptions.ValidationError,
          .invalidActivityBatchID
        )
      }
    }
  }

  func testTaskScopedBatchIDIsReappliedAcrossRetries() async throws {
    await MockURLProtocol.reset()
    let recorder = RequestOptionsRecorder()
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    let client = ArcaneClient(
      configuration: .init(
        baseURL: URL(string: "https://arcane.example.com/base")!,
        urlSession: URLSession(configuration: configuration),
        retryPolicy: .init(
          maxAttempts: 2,
          baseBackoff: .milliseconds(1),
          maxBackoff: .milliseconds(1)
        )
      )
    )

    await MockURLProtocol.setHandler { request in
      let attempt = await recorder.record(request)
      let response = try XCTUnwrap(
        HTTPURLResponse(
          url: XCTUnwrap(request.url),
          statusCode: attempt == 1 ? 503 : 200,
          httpVersion: nil,
          headerFields: ["Content-Type": "application/json"]
        )
      )
      let body =
        attempt == 1
        ? Data(#"{"message":"retry"}"#.utf8)
        : Data(#"{"success":true,"data":{"syncResults":[]}}"#.utf8)
      return (response, body)
    }

    let options = try ArcaneRequestOptions(activityBatchID: "bulk_update-1")
    let result = try await client
      .withRequestOptions(options)
      .variables
      .update(id: "var_1", request: .init(value: "updated"))

    XCTAssertTrue(result.syncResults.isEmpty)
    let requests = await recorder.snapshot()
    XCTAssertEqual(requests.count, 2)
    XCTAssertEqual(requests.map(\.method), ["PUT", "PUT"])
    XCTAssertEqual(requests.map(\.path), ["/base/api/variables/var_1", "/base/api/variables/var_1"])
    XCTAssertEqual(requests.map(\.batchID), ["bulk_update-1", "bulk_update-1"])
  }
}

private struct RecordedRequestOptions: Sendable {
  let method: String
  let path: String
  let batchID: String?
}

private actor RequestOptionsRecorder {
  private var requests: [RecordedRequestOptions] = []

  func record(_ request: URLRequest) -> Int {
    requests.append(
      RecordedRequestOptions(
        method: request.httpMethod ?? "",
        path: request.url?.path ?? "",
        batchID: request.value(forHTTPHeaderField: "X-Arcane-Batch-Id")
      )
    )
    return requests.count
  }

  func snapshot() -> [RecordedRequestOptions] {
    requests
  }
}
