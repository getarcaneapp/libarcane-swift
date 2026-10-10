import Foundation
import Synchronization
import XCTest

@testable import Arcane

final class TransportBehaviorTests: XCTestCase {
  private let mock = MockURLProtocolSession()
  func testMultipartUploadStreamRemovesPreparedTempFileWhenOpenFails() async throws {
    let inputURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("arcane-upload-input-\(UUID().uuidString).txt")
    try Data("payload".utf8).write(to: inputURL)
    defer { try? FileManager.default.removeItem(at: inputURL) }

    let transport = makeLoopbackTransport()
    let before = multipartTempFileNames()
    let stream: NDJSONStream<AnyDecodable> = transport.multipartUploadStream(
      "upload",
      files: [MultipartFile(fieldName: "file", filename: "input.txt", fileURL: inputURL)]
    )

    do {
      var iterator = stream.makeAsyncIterator()
      _ = try await iterator.next()
      XCTFail("Expected multipart stream open to fail")
    } catch {
      XCTAssertFalse(error is CancellationError)
    }

    XCTAssertEqual(multipartTempFileNames(), before)
  }

  func testMultipartFilePartSeparatesHeadersFromPayloadWithBlankLine() throws {
    let inputURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("arcane-upload-input-\(UUID().uuidString).txt")
    try Data("payload".utf8).write(to: inputURL)
    defer { try? FileManager.default.removeItem(at: inputURL) }

    let transport = makeLoopbackTransport()
    let prepared = try transport.makeMultipartTempFile(
      fields: [:],
      files: [
        MultipartFile(
          fieldName: "file", filename: "input.txt", contentType: "text/plain", fileURL: inputURL)
      ]
    )
    defer { try? FileManager.default.removeItem(at: prepared.url) }

    let body = try String(contentsOf: prepared.url, encoding: .utf8)
    XCTAssertTrue(
      body.contains("Content-Type: text/plain\r\n\r\npayload"),
      "Multipart file headers must end with a CRLF blank line before the payload"
    )
  }

  func testWebSocketChannelClosesUnderlyingConnectionWhenConsumerStopsIterating() async throws {
    let probe = WebSocketProbe()
    let channel = WebSocketChannel<Never, String>(
      operations: .init(
        receive: { try await probe.receive() },
        send: { _ in XCTFail("Unexpected send on receive-only channel") },
        sendPing: { XCTFail("Unexpected ping on receive-only channel") },
        close: { code, reason in await probe.close(code: code, reason: reason) }
      ),
      encodeOutbound: { _ in fatalError("Receive-only channel") },
      decodeInbound: { message in
        switch message {
        case .string(let text):
          return text
        case .data(let data):
          guard let text = String(bytes: data, encoding: .utf8) else {
            throw ArcaneError.decoding("Test frame was not valid UTF-8")
          }
          return text
        @unknown default:
          throw ArcaneError.transport("Unsupported test frame")
        }
      }
    )

    let reader = Task {
      var iterator = channel.messages.makeAsyncIterator()
      return try await iterator.next()
    }
    await probe.enqueue(.string("hello"))

    let firstMessage = try await reader.value
    XCTAssertEqual(firstMessage, "hello")
    try await waitForCloseCount(probe, expectedCount: 1)
    let closeCount = await probe.closeCount()
    XCTAssertEqual(closeCount, 1)
  }

  func testWebSocketChannelCanKeepOnlyNewestSnapshot() async throws {
    let probe = WebSocketProbe()
    let channel = WebSocketChannel<Never, String>(
      operations: .init(
        receive: { try await probe.receive() },
        send: { _ in },
        sendPing: {},
        close: { code, reason in await probe.close(code: code, reason: reason) }
      ),
      encodeOutbound: { _ in fatalError("Receive-only channel") },
      decodeInbound: { message in
        switch message {
        case .string(let text): return text
        case .data(let data):
          guard let text = String(bytes: data, encoding: .utf8) else {
            throw ArcaneError.decoding("Test frame was not valid UTF-8")
          }
          return text
        @unknown default: throw ArcaneError.transport("Unsupported frame")
        }
      }
    )

    var iterator: AsyncThrowingStream<String, Error>.Iterator? =
      channel
      .messages(bufferingPolicy: .bufferingNewest(1))
      .makeAsyncIterator()
    await probe.enqueue(.string("first"))
    await probe.enqueue(.string("second"))
    await probe.enqueue(.string("latest"))
    // The reader asks for a fourth frame only after yielding all three queued
    // values, which proves the buffer has settled on the newest snapshot.
    try await waitForReceiveCount(probe, expectedCount: 4)

    let value = try await iterator?.next()
    XCTAssertEqual(value, "latest")
    iterator = nil
    try await waitForCloseCount(probe, expectedCount: 1)
    let closeCount = await probe.closeCount()
    XCTAssertEqual(closeCount, 1)
  }

  @diagnose(DeprecatedDeclaration, as: ignored, reason: "URLSession subclasses cannot use its configuration factory initializer")
  func testWebSocketStreamsUseConfiguredURLSession() async throws {
    let session = RecordingWebSocketSession()
    let client = ArcaneClient(
      configuration: .init(
        baseURL: URL(string: "http://127.0.0.1:1")!,
        tokenStore: InMemoryTokenStore(),
        urlSession: session,
        retryPolicy: RetryPolicy(
          maxAttempts: 1, baseBackoff: .milliseconds(1), maxBackoff: .milliseconds(1))
      ))

    let logTask = Task {
      let iterator = client.containers.logs(envID: "0", id: "container-id").makeAsyncIterator()
      return try await iterator.next()
    }
    try await waitForWebSocketTasks(session, expectedCount: 1)
    logTask.cancel()

    let statsTask = Task {
      let iterator = client.containers
        .stats(envID: "0", id: "container-id")
        .makeAsyncIterator()
      return try await iterator.next()
    }
    try await waitForWebSocketTasks(session, expectedCount: 2)
    statsTask.cancel()

    let terminal = try await client.containers.exec(envID: "0", id: "container-id")
    try await waitForWebSocketTasks(session, expectedCount: 3)
    await terminal.close()
  }

  private func makeLoopbackTransport() -> ArcaneURLSessionTransport {
    ArcaneURLSessionTransport(
      baseURL: URL(string: "http://127.0.0.1:1")!,
      session: URLSession(configuration: .ephemeral),
      authManager: AuthManager(
        baseURL: URL(string: "http://127.0.0.1:1")!,
        tokenStore: InMemoryTokenStore(),
        apiKey: nil,
        urlSession: URLSession(configuration: .ephemeral),
        decoder: ArcaneJSON.makeDecoder(),
        encoder: ArcaneJSON.makeEncoder()
      ),
      retryPolicy: RetryPolicy(
        maxAttempts: 1, baseBackoff: .milliseconds(1), maxBackoff: .milliseconds(1)),
      decoder: ArcaneJSON.makeDecoder(),
      encoder: ArcaneJSON.makeEncoder()
    )
  }

  private func multipartTempFileNames() -> Set<String> {
    let tempDirectory = FileManager.default.temporaryDirectory
    guard
      let contents = try? FileManager.default.contentsOfDirectory(
        at: tempDirectory,
        includingPropertiesForKeys: nil
      )
    else {
      return []
    }
    return Set(
      contents
        .map(\.lastPathComponent)
        .filter { $0.hasPrefix("arcane-multipart-") }
    )
  }

  private func waitForWebSocketTasks(
    _ session: RecordingWebSocketSession,
    expectedCount: Int
  ) async throws {
    let deadline = Date().addingTimeInterval(1)
    while session.webSocketTaskCount < expectedCount, Date() < deadline {
      try await Task.sleep(for: .milliseconds(10))
    }
    XCTAssertEqual(session.webSocketTaskCount, expectedCount)
  }

  private func waitForCloseCount(
    _ probe: WebSocketProbe,
    expectedCount: Int
  ) async throws {
    let deadline = Date().addingTimeInterval(1)
    while await probe.closeCount() < expectedCount, Date() < deadline {
      try await Task.sleep(for: .milliseconds(10))
    }
    let closeCount = await probe.closeCount()
    XCTAssertGreaterThanOrEqual(closeCount, expectedCount)
  }

  private func waitForReceiveCount(
    _ probe: WebSocketProbe,
    expectedCount: Int
  ) async throws {
    let deadline = Date().addingTimeInterval(1)
    while await probe.receiveCount() < expectedCount, Date() < deadline {
      try await Task.sleep(for: .milliseconds(10))
    }
    let receiveCount = await probe.receiveCount()
    XCTAssertEqual(receiveCount, expectedCount)
  }
}

private final class RecordingWebSocketSession: URLSession, @unchecked Sendable {
  private let fallback = URLSession(configuration: .ephemeral)
  private let count = Mutex(0)

  var webSocketTaskCount: Int {
    count.withLock { $0 }
  }

  override func webSocketTask(with request: URLRequest) -> URLSessionWebSocketTask {
    count.withLock { $0 += 1 }
    return fallback.webSocketTask(with: request)
  }
}

private actor WebSocketProbe {
  private var bufferedMessages: [URLSessionWebSocketTask.Message] = []
  private var pendingReceivers: [CheckedContinuation<URLSessionWebSocketTask.Message, Error>] = []
  private var closeCalls = 0
  private var receiveCalls = 0

  func enqueue(_ message: URLSessionWebSocketTask.Message) {
    if pendingReceivers.isEmpty {
      bufferedMessages.append(message)
      return
    }
    let receiver = pendingReceivers.removeFirst()
    receiver.resume(returning: message)
  }

  func receive() async throws -> URLSessionWebSocketTask.Message {
    receiveCalls += 1
    if !bufferedMessages.isEmpty {
      return bufferedMessages.removeFirst()
    }
    return try await withCheckedThrowingContinuation { continuation in
      pendingReceivers.append(continuation)
    }
  }

  func close(code: URLSessionWebSocketTask.CloseCode, reason: Data?) {
    closeCalls += 1
    let receivers = pendingReceivers
    pendingReceivers.removeAll()
    for receiver in receivers {
      receiver.resume(throwing: CancellationError())
    }
    _ = code
    _ = reason
  }

  func closeCount() -> Int {
    closeCalls
  }

  func receiveCount() -> Int {
    receiveCalls
  }
}
