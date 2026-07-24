import Foundation
import XCTest

@testable import Arcane

final class OperationStreamTests: XCTestCase {
  func testOperationEventDecodesCurrentAndLegacyFrames() throws {
    let decoder = ArcaneJSON.makeDecoder()
    let current = try decoder.decode(
      OperationStreamEvent.self,
      from: Data(
        #"{"type":"activity","activityId":"act-1","log":"building","done":false}"#.utf8
      )
    )
    XCTAssertEqual(current.type, "activity")
    XCTAssertEqual(current.activityID, "act-1")
    XCTAssertEqual(current.log, "building")
    XCTAssertEqual(current.done, false)

    let legacy = try decoder.decode(
      OperationStreamEvent.self,
      from: Data(
        #"""
        {
          "status": "Downloading",
          "id": "layer-1",
          "progress": "50%",
          "progressDetail": {"current": 5, "total": 10},
          "stream": "legacy output",
          "phase": "pull",
          "service": "web"
        }
        """#.utf8
      )
    )
    XCTAssertEqual(legacy.status, "Downloading")
    XCTAssertEqual(legacy.id, "layer-1")
    XCTAssertEqual(legacy.progress, "50%")
    XCTAssertEqual(legacy.progressDetail?.current, 5)
    XCTAssertEqual(legacy.progressDetail?.total, 10)
    XCTAssertEqual(legacy.stream, "legacy output")
    XCTAssertEqual(legacy.phase, "pull")
    XCTAssertEqual(legacy.service, "web")
  }

  func testDoneFrameFinishesSplitStreamAndCancelsHeldRequest() async throws {
    await MockURLProtocol.reset()
    let client = makeClient()
    await MockURLProtocol.setStreamingHandler { request in
      let response = try Self.streamResponse(for: request)
      return MockURLProtocolStreamResponse(
        response: response,
        chunks: [
          Data("{\"type\":\"activity\",\"activityId\":\"act-1\"}\n{\"lo".utf8),
          Data(
            "g\":\"Building image\"}\n{\"status\":\"Downloading\",\"id\":\"layer-1\",".utf8
          ),
          Data("\"progressDetail\":{\"current\":5,\"total\":10}}\n{\"done\":true}\n".utf8)
        ],
        holdOpen: true
      )
    }

    let stream = try client.projects.deployStream(projectID: "project-1")
    let events = try await valueBeforeTimeout {
      var values: [OperationStreamEvent] = []
      for try await event in stream {
        values.append(event)
      }
      return values
    }

    XCTAssertEqual(events.count, 4)
    XCTAssertEqual(events[0].activityID, "act-1")
    XCTAssertEqual(events[1].log, "Building image")
    XCTAssertEqual(events[2].progressDetail?.current, 5)
    XCTAssertEqual(events[3].done, true)
    try await waitForRequestCleanup()
  }

  func testNoProgressHelpersUseFiniteDoneTermination() async throws {
    let operations: [@Sendable (ArcaneClient) async throws -> Void] = [
      { try await $0.projects.deploy(projectID: "project") },
      { try await $0.projects.redeploy(projectID: "project") },
      { try await $0.projects.pullImages(projectID: "project") },
      { try await $0.projects.build(projectID: "project") },
      {
        try await $0.images.pull(
          options: ImagePullOptions(imageName: "alpine", tag: "latest")
        )
      },
      {
        try await $0.images.build(
          request: ImageBuildRequest(
            contextDir: "https://example.com/source.git",
            dockerfile: "Dockerfile",
            tags: ["example:test"]
          )
        )
      }
    ]

    for operation in operations {
      await MockURLProtocol.reset()
      let client = makeClient()
      await MockURLProtocol.setStreamingHandler { request in
        MockURLProtocolStreamResponse(
          response: try Self.streamResponse(for: request),
          chunks: [
            Data("{\"type\":\"activity\",\"activityId\":\"act\"}\n{\"done\":true}\n".utf8)
          ],
          holdOpen: true
        )
      }

      try await valueBeforeTimeout {
        try await operation(client)
      }
      try await waitForRequestCleanup()
    }
  }

  func testOperationErrorFrameThrowsTypedServerError() async throws {
    await MockURLProtocol.reset()
    let client = makeClient()
    await MockURLProtocol.setStreamingHandler { request in
      MockURLProtocolStreamResponse(
        response: try Self.streamResponse(for: request),
        chunks: [
          Data(
            "{\"type\":\"activity\",\"activityId\":\"act-3\"}\n{\"error\":\"build failed\"}\n"
              .utf8
          )
        ],
        holdOpen: true
      )
    }

    do {
      try await valueBeforeTimeout {
        let stream = try client.images.buildStream(
          request: ImageBuildRequest(
            contextDir: "https://example.com/source.git",
            dockerfile: "Dockerfile",
            tags: ["example:test"]
          )
        )
        for try await _ in stream {}
      }
      XCTFail("Expected the operation error frame to throw")
    } catch {
      XCTAssertEqual(
        error as? ArcaneError,
        .server(code: "OPERATION_FAILED", message: "build failed")
      )
    }
    try await waitForRequestCleanup()
  }

  func testConsumerCancellationCleansUpRequest() async throws {
    await MockURLProtocol.reset()
    let client = makeClient()
    await MockURLProtocol.setStreamingHandler { request in
      MockURLProtocolStreamResponse(
        response: try Self.streamResponse(for: request),
        chunks: [
          Data("{\"type\":\"activity\",\"activityId\":\"act-4\"}\n{\"log\":\"working\"}\n".utf8)
        ],
        holdOpen: true
      )
    }

    let stream = try client.images.pullStream(
      options: ImagePullOptions(imageName: "alpine:latest")
    )
    let consumer = Task {
      for try await _ in stream {}
    }
    try await waitForRequestStart()
    consumer.cancel()
    _ = await consumer.result
    try await waitForRequestCleanup()
  }

  func testActivityStreamRemainsOpenUntilConsumerCancellation() async throws {
    await MockURLProtocol.reset()
    let client = makeClient()
    await MockURLProtocol.setStreamingHandler { request in
      MockURLProtocolStreamResponse(
        response: try Self.streamResponse(for: request),
        chunks: [
          Data(
            "{\"type\":\"heartbeat\",\"done\":true,\"timestamp\":\"2026-07-24T12:00:00Z\"}\n"
              .utf8
          )
        ],
        holdOpen: true
      )
    }

    try await assertRemainsOpen(client.activities.stream())
  }

  func testDashboardStreamRemainsOpenUntilConsumerCancellation() async throws {
    await MockURLProtocol.reset()
    let client = makeClient()
    await MockURLProtocol.setStreamingHandler { request in
      MockURLProtocolStreamResponse(
        response: try Self.streamResponse(for: request),
        chunks: [
          Data(
            "{\"type\":\"heartbeat\",\"done\":true,\"timestamp\":\"2026-07-24T12:00:00Z\"}\n"
              .utf8
          )
        ],
        holdOpen: true
      )
    }

    try await assertRemainsOpen(client.dashboard.stream())
  }

  private func makeClient() -> ArcaneClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return ArcaneClient(
      configuration: .init(
        baseURL: URL(string: "https://arcane.example.com/base")!,
        urlSession: URLSession(configuration: configuration)
      )
    )
  }

  private static func streamResponse(for request: URLRequest) throws -> HTTPURLResponse {
    try XCTUnwrap(
      HTTPURLResponse(
        url: XCTUnwrap(request.url),
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/x-ndjson"]
      )
    )
  }

  private func valueBeforeTimeout<Value: Sendable>(
    _ operation: @escaping @Sendable () async throws -> Value
  ) async throws -> Value {
    try await withThrowingTaskGroup(of: Value.self) { group in
      group.addTask(operation: operation)
      group.addTask {
        try await Task.sleep(for: .seconds(2))
        throw TestTimeout.expired
      }
      defer { group.cancelAll() }
      guard let value = try await group.next() else {
        throw TestTimeout.expired
      }
      return value
    }
  }

  private func assertRemainsOpen<Element: Decodable & Sendable>(
    _ stream: NDJSONStream<Element>
  ) async throws {
    let probe = StreamProbe()
    let consumer = Task {
      do {
        for try await _ in stream {
          await probe.recordEvent()
        }
      } catch {
        // Cancellation is the expected terminal path for this assertion.
      }
      await probe.recordCompletion()
    }

    try await waitUntil {
      await probe.eventCount > 0
    }
    try await Task.sleep(for: .milliseconds(100))
    let completed = await probe.completed
    XCTAssertFalse(completed)

    consumer.cancel()
    _ = await consumer.result
    try await waitForRequestCleanup()
  }

  private func waitForRequestStart() async throws {
    try await waitUntil {
      await MockURLProtocol.requestCount() > 0
    }
  }

  private func waitForRequestCleanup() async throws {
    try await waitUntil {
      await MockURLProtocol.stopLoadingCount() > 0
    }
  }

  private func waitUntil(
    _ condition: @escaping @Sendable () async -> Bool
  ) async throws {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: .seconds(2))
    while !(await condition()) {
      guard clock.now < deadline else {
        throw TestTimeout.expired
      }
      try await Task.sleep(for: .milliseconds(10))
    }
  }
}

private enum TestTimeout: Error {
  case expired
}

private actor StreamProbe {
  private(set) var eventCount = 0
  private(set) var completed = false

  func recordEvent() {
    eventCount += 1
  }

  func recordCompletion() {
    completed = true
  }
}
