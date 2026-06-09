@testable import Arcane
import Foundation
import XCTest

final class TransportBehaviorTests: XCTestCase {
    func testArcaneJSONDecodesFractionalSecondsDates() throws {
        struct Payload: Decodable {
            let createdAt: Date
        }

        let decoder = ArcaneJSON.makeDecoder()
        let payload = try decoder.decode(
            Payload.self,
            from: Data(#"{"createdAt":"2026-06-08T20:46:08.123Z"}"#.utf8)
        )

        XCTAssertEqual(payload.createdAt.timeIntervalSince1970, 1_780_951_568.123, accuracy: 0.000_1)
    }

    func testArcaneJSONDecodesNonFractionalSecondsDates() throws {
        struct Payload: Decodable {
            let createdAt: Date
        }

        let decoder = ArcaneJSON.makeDecoder()
        let payload = try decoder.decode(
            Payload.self,
            from: Data(#"{"createdAt":"2026-06-08T20:46:08Z"}"#.utf8)
        )

        XCTAssertEqual(payload.createdAt.timeIntervalSince1970, 1_780_951_568, accuracy: 0.000_1)
    }

    func testRefreshTokensDeduplicatesConcurrentRefreshRequests() async throws {
        struct ResponseEnvelope: Encodable {
            let success: Bool
            let data: TokenRefreshResponse
        }

        await MockURLProtocol.reset()
        let session = makeMockURLSession()
        let originalTokens = TokenPair(
            accessToken: "stale-access-token",
            refreshToken: "refresh-token",
            expiresAt: Date(timeIntervalSince1970: 1_780_945_500)
        )
        let refreshedTokens = TokenPair(
            accessToken: "fresh-access-token",
            refreshToken: "fresh-refresh-token",
            expiresAt: Date(timeIntervalSince1970: 1_780_945_900)
        )
        let store = InMemoryTokenStore(tokens: originalTokens)
        let authManager = AuthManager(
            baseURL: URL(string: "https://arcane.example.com")!,
            tokenStore: store,
            apiKey: nil,
            urlSession: session,
            decoder: ArcaneJSON.makeDecoder(),
            encoder: ArcaneJSON.makeEncoder()
        )

        await MockURLProtocol.setHandler { request in
            try await Task.sleep(for: .milliseconds(50))
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
            )
            let envelope = ResponseEnvelope(
                success: true,
                data: TokenRefreshResponse(
                    token: refreshedTokens.accessToken,
                    refreshToken: refreshedTokens.refreshToken,
                    expiresAt: refreshedTokens.expiresAt
                )
            )
            let data = try ArcaneJSON.makeEncoder().encode(envelope)
            return (response, data)
        }

        async let first = authManager.refreshTokens()
        async let second = authManager.refreshTokens()
        let firstTokens = try await first
        let secondTokens = try await second
        let requestCount = await MockURLProtocol.requestCount()
        let storedTokens = try await store.loadTokens()

        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(firstTokens, refreshedTokens)
        XCTAssertEqual(secondTokens, refreshedTokens)
        XCTAssertEqual(storedTokens, refreshedTokens)
    }

    func testRefreshTokensKeepsStoredTokensOnTransientServerFailure() async throws {
        await MockURLProtocol.reset()
        let session = makeMockURLSession()
        let originalTokens = TokenPair(
            accessToken: "stale-access-token",
            refreshToken: "refresh-token",
            expiresAt: Date(timeIntervalSince1970: 1_780_945_500)
        )
        let store = InMemoryTokenStore(tokens: originalTokens)
        let authManager = AuthManager(
            baseURL: URL(string: "https://arcane.example.com")!,
            tokenStore: store,
            apiKey: nil,
            urlSession: session,
            decoder: ArcaneJSON.makeDecoder(),
            encoder: ArcaneJSON.makeEncoder()
        )

        await MockURLProtocol.setHandler { request in
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: XCTUnwrap(request.url),
                    statusCode: 503,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
            )
            return (response, Data(#"{"message":"try again later"}"#.utf8))
        }

        do {
            _ = try await authManager.refreshTokens()
            XCTFail("Expected refresh to fail")
        } catch {
            guard case let ArcaneError.server(code, message) = error else {
                return XCTFail("Expected server error, got \(error)")
            }
            XCTAssertEqual(code, "HTTP_503")
            XCTAssertEqual(message, "try again later")
        }

        let storedTokens = try await store.loadTokens()
        XCTAssertEqual(storedTokens, originalTokens)
    }

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
                MultipartFile(fieldName: "file", filename: "input.txt", contentType: "text/plain", fileURL: inputURL)
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
                close: { code, reason in await probe.close(code: code, reason: reason) }
            ),
            encodeOutbound: { _ in fatalError("Receive-only channel") },
            decodeInbound: { message in
                switch message {
                case let .string(text):
                    return text
                case let .data(data):
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
    }

    func testWebSocketStreamsUseConfiguredURLSession() async throws {
        let session = RecordingWebSocketSession()
        let client = ArcaneClient(configuration: .init(
            baseURL: URL(string: "http://127.0.0.1:1")!,
            tokenStore: InMemoryTokenStore(),
            urlSession: session,
            retryPolicy: RetryPolicy(maxAttempts: 1, baseBackoff: .milliseconds(1), maxBackoff: .milliseconds(1))
        ))

        var logIterator: LogStream.AsyncIterator? = client.containers
            .logs(envID: "0", id: "container-id")
            .makeAsyncIterator()
        XCTAssertNotNil(logIterator)
        try await waitForWebSocketTasks(session, expectedCount: 1)
        logIterator = nil

        var statsIterator: AsyncThrowingStream<ContainerStatsPayload, Error>.Iterator? = client.containers
            .stats(envID: "0", id: "container-id")
            .makeAsyncIterator()
        XCTAssertNotNil(statsIterator)
        try await waitForWebSocketTasks(session, expectedCount: 2)
        statsIterator = nil

        let terminal = try await client.containers.exec(envID: "0", id: "container-id")
        try await waitForWebSocketTasks(session, expectedCount: 3)
        await terminal.close()
    }

    private func makeMockURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
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
            retryPolicy: RetryPolicy(maxAttempts: 1, baseBackoff: .milliseconds(1), maxBackoff: .milliseconds(1)),
            decoder: ArcaneJSON.makeDecoder(),
            encoder: ArcaneJSON.makeEncoder()
        )
    }

    private func multipartTempFileNames() -> Set<String> {
        let tempDirectory = FileManager.default.temporaryDirectory
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: tempDirectory,
            includingPropertiesForKeys: nil
        ) else {
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
}

private final class RecordingWebSocketSession: URLSession, @unchecked Sendable {
    private let lock = NSLock()
    private let fallback = URLSession(configuration: .ephemeral)
    private var count = 0

    var webSocketTaskCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }

    override func webSocketTask(with request: URLRequest) -> URLSessionWebSocketTask {
        lock.lock()
        count += 1
        lock.unlock()
        return fallback.webSocketTask(with: request)
    }
}

private actor WebSocketProbe {
    private var bufferedMessages: [URLSessionWebSocketTask.Message] = []
    private var pendingReceivers: [CheckedContinuation<URLSessionWebSocketTask.Message, Error>] = []
    private var closeCalls = 0

    func enqueue(_ message: URLSessionWebSocketTask.Message) {
        if pendingReceivers.isEmpty {
            bufferedMessages.append(message)
            return
        }
        let receiver = pendingReceivers.removeFirst()
        receiver.resume(returning: message)
    }

    func receive() async throws -> URLSessionWebSocketTask.Message {
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
}
