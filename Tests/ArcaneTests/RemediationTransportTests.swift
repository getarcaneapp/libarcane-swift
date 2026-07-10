import Foundation
import XCTest

@testable import Arcane

final class RemediationTransportTests: XCTestCase {
  func testPublic401DoesNotClearAnActiveSession() async throws {
    let tokens = tokenPair(access: "active", refresh: "refresh")
    let store = InMemoryTokenStore(tokens: tokens)
    let client = makeClient(store: store)
    await respond(status: 401)

    do {
      _ = try await client.transport.rawRequest(
        "settings/public",
        body: Optional<EmptyBody>.none,
        authorized: false
      )
      XCTFail("Expected unauthorized response")
    } catch ArcaneError.unauthorized {}

    let storedTokens = try await store.loadTokens()
    XCTAssertEqual(storedTokens, tokens)
  }

  func testFinalAuthorized401DoesNotClearAReplacementCredential() async throws {
    let oldTokens = tokenPair(access: "old", refresh: "")
    let replacementTokens = tokenPair(access: "replacement", refresh: "", lifetime: 7_200)
    let store = InMemoryTokenStore(tokens: oldTokens)
    let client = makeClient(store: store)
    await MockURLProtocol.reset()
    await MockURLProtocol.setHandler { request in
      try await Task.sleep(for: .milliseconds(100))
      return (try Self.response(for: request, status: 401), Data())
    }

    let requestTask = Task {
      try await client.transport.rawRequest("protected", body: Optional<EmptyBody>.none)
    }
    try await waitForRequestCount(1)
    try await client.authManager.save(tokens: replacementTokens)
    do {
      _ = try await requestTask.value
      XCTFail("Expected unauthorized response")
    } catch ArcaneError.unauthorized {}

    let storedTokens = try await store.loadTokens()
    XCTAssertEqual(storedTokens, replacementTokens)
  }

  func testOfflineLogoutStillClearsLocalCredentials() async throws {
    let store = InMemoryTokenStore(tokens: tokenPair(access: "active", refresh: "refresh"))
    let client = makeClient(store: store)
    await MockURLProtocol.reset()
    await MockURLProtocol.setHandler { _ in throw URLError(.notConnectedToInternet) }

    do {
      try await client.auth.logout()
      XCTFail("Expected remote logout failure")
    } catch {}

    let storedTokens = try await store.loadTokens()
    XCTAssertNil(storedTokens)
  }

  func testRefreshCannotRestoreCredentialsAfterClear() async throws {
    struct ResponseEnvelope: Encodable {
      let success: Bool
      let data: TokenRefreshResponse
    }

    let store = InMemoryTokenStore(
      tokens: tokenPair(access: "old", refresh: "refresh", lifetime: -60)
    )
    let client = makeClient(store: store)
    await MockURLProtocol.reset()
    await MockURLProtocol.setHandler { request in
      try await Task.sleep(for: .milliseconds(150))
      let refreshed = TokenRefreshResponse(
        token: "new",
        refreshToken: "new-refresh",
        expiresAt: Date(timeIntervalSinceNow: 3_600)
      )
      return (
        try Self.response(for: request, status: 200),
        try ArcaneJSON.makeEncoder().encode(ResponseEnvelope(success: true, data: refreshed))
      )
    }

    let refreshTask = Task { try await client.authManager.refreshTokens() }
    try await waitForRequestCount(1)
    try await client.authManager.clear()
    do {
      _ = try await refreshTask.value
      XCTFail("Expected refresh cancellation")
    } catch is CancellationError {}

    try await Task.sleep(for: .milliseconds(200))
    let storedTokens = try await store.loadTokens()
    XCTAssertNil(storedTokens)
  }

  func testCancelledURLRequestThrowsCancellationError() async throws {
    let client = makeClient()
    await MockURLProtocol.reset()
    await MockURLProtocol.setHandler { _ in throw URLError(.cancelled) }

    do {
      _ = try await client.transport.rawRequest(
        "public",
        body: Optional<EmptyBody>.none,
        authorized: false
      )
      XCTFail("Expected cancellation")
    } catch is CancellationError {}
  }

  func testDestinationDownloadRetriesAndAtomicallyReplacesFile() async throws {
    let counter = RemediationCallCounter()
    let client = makeClient(maxAttempts: 2)
    await MockURLProtocol.reset()
    await MockURLProtocol.setHandler { request in
      let attempt = await counter.increment()
      return (
        try Self.response(for: request, status: attempt == 1 ? 503 : 200),
        Data((attempt == 1 ? "retry" : "new payload").utf8)
      )
    }

    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("arcane-download-test-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let destination = directory.appendingPathComponent("backup.tar")
    try Data("old payload".utf8).write(to: destination)

    try await client.transport.downloadRaw("download", authorized: false, to: destination)

    XCTAssertEqual(try String(contentsOf: destination, encoding: .utf8), "new payload")
    let attempts = await counter.value()
    XCTAssertEqual(attempts, 2)
    let leftovers = try FileManager.default.contentsOfDirectory(atPath: directory.path)
      .filter { $0.contains("arcane-download-") }
    XCTAssertTrue(leftovers.isEmpty)
  }

  private func makeClient(
    store: InMemoryTokenStore = InMemoryTokenStore(),
    maxAttempts: Int = 1
  ) -> ArcaneClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return ArcaneClient(
      configuration: .init(
        baseURL: URL(string: "https://arcane.example.com")!,
        tokenStore: store,
        urlSession: URLSession(configuration: configuration),
        retryPolicy: .init(
          maxAttempts: maxAttempts,
          baseBackoff: .milliseconds(1),
          maxBackoff: .milliseconds(1)
        )
      )
    )
  }

  private func tokenPair(
    access: String,
    refresh: String,
    lifetime: TimeInterval = 3_600
  ) -> TokenPair {
    TokenPair(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: Date(timeIntervalSinceNow: lifetime)
    )
  }

  private func respond(status: Int) async {
    await MockURLProtocol.reset()
    await MockURLProtocol.setHandler { request in
      (try Self.response(for: request, status: status), Data())
    }
  }

  private static func response(for request: URLRequest, status: Int) throws -> HTTPURLResponse {
    try XCTUnwrap(
      HTTPURLResponse(
        url: XCTUnwrap(request.url), statusCode: status, httpVersion: nil, headerFields: nil)
    )
  }

  private func waitForRequestCount(_ expectedCount: Int) async throws {
    let deadline = Date().addingTimeInterval(1)
    while await MockURLProtocol.requestCount() < expectedCount, Date() < deadline {
      try await Task.sleep(for: .milliseconds(10))
    }
    let requestCount = await MockURLProtocol.requestCount()
    XCTAssertEqual(requestCount, expectedCount)
  }
}

private actor RemediationCallCounter {
  private var count = 0

  func increment() -> Int {
    count += 1
    return count
  }

  func value() -> Int { count }
}
