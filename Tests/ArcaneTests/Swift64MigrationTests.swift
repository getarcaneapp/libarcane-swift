import Foundation
import Synchronization
import Testing

@testable import Arcane

@Suite("Swift 6.4 migration")
struct Swift64MigrationTests {
  @Test(arguments: [1, 2, 3, 4, 5, Int.max])
  func retryBackoffCapsWithoutOverflow(attempt: Int) {
    let client = ArcaneClient(configuration: .init(baseURL: migrationBaseURL))
    let expected: Duration
    switch attempt {
    case 1: expected = .milliseconds(150)
    case 2: expected = .milliseconds(300)
    case 3: expected = .milliseconds(600)
    case 4: expected = .milliseconds(1_200)
    default: expected = .seconds(2)
    }
    #expect(client.transport.retryDelay(attempt: attempt) == expected)
  }

  @Test(arguments: [Duration.zero, .seconds(-1), .seconds(Int64.max)])
  func retryBackoffHandlesExtremeBase(base: Duration) {
    let policy = RetryPolicy(maxAttempts: 3, baseBackoff: base, maxBackoff: .seconds(2))
    let client = ArcaneClient(configuration: .init(baseURL: migrationBaseURL, retryPolicy: policy))
    #expect(client.transport.retryDelay(attempt: Int.max) == (base > .zero ? .seconds(2) : .zero))
  }

  @Test(arguments: [Duration.zero, .seconds(-1), .seconds(Int64.max)])
  func retryBackoffHandlesExtremeCap(cap: Duration) {
    let policy = RetryPolicy(maxAttempts: 3, baseBackoff: .milliseconds(150), maxBackoff: cap)
    let client = ArcaneClient(configuration: .init(baseURL: migrationBaseURL, retryPolicy: policy))
    #expect(client.transport.retryDelay(attempt: Int.max) == max(.zero, cap))
  }

  @Test(arguments: [false, true])
  func cancelledUploadAwaitsCleanupAndPreservesCancellation(cleanupFails: Bool) async throws {
    let mock = MockURLProtocolSession()
    let methods = Mutex<[String]>([])
    let client = migrationClient(mock)
    let file = try migrationUploadFile()
    defer { try? FileManager.default.removeItem(at: file) }
    await mock.setHandler { request in
      methods.withLock { $0.append(request.httpMethod ?? "") }
      if request.httpMethod == "DELETE" {
        return try migrationResponse(request, status: cleanupFails ? 403 : 204, data: Data())
      }
      return try migrationResponse(request, data: migrationUploadResponse(request))
    }
    let operation = Task {
      try await client.uploads.uploadFile(kind: .volumeBackup, fileURL: file) { _ in
        withUnsafeCurrentTask { $0?.cancel() }
      }
    }
    await #expect(throws: CancellationError.self) { try await operation.value }
    // This is asserted immediately after the operation returns; detached cleanup would race.
    #expect(methods.withLock { $0 } == ["POST", "PUT", "DELETE"])
  }

  @Test func successfulUploadRetainsSession() async throws {
    let mock = MockURLProtocolSession()
    let methods = Mutex<[String]>([])
    let progress = Mutex<[Int64]>([])
    let client = migrationClient(mock)
    let file = try migrationUploadFile()
    defer { try? FileManager.default.removeItem(at: file) }
    await mock.setHandler { request in
      methods.withLock { $0.append(request.httpMethod ?? "") }
      return try migrationResponse(request, data: migrationUploadResponse(request))
    }
    let id = try await client.uploads.uploadFile(kind: .volumeBackup, fileURL: file) { update in
      progress.withLock { $0.append(update.bytesDone) }
    }
    #expect(id == "session")
    #expect(methods.withLock { $0 } == ["POST", "PUT", "PUT", "GET"])
    #expect(progress.withLock { $0 } == [3, 5])
  }

  @Test(arguments: [false, true], [false, true])
  func credentialRollbackIsUncancelledAndPreservesOriginalError(
    writeThrows: Bool, rollbackThrows: Bool
  ) async throws {
    let initial = migrationTokens("accepted")
    let store = MigrationTokenStore(tokens: initial, writeThrows: writeThrows, rollbackThrows: rollbackThrows)
    let client = migrationClient(MockURLProtocolSession(), store: store)
    let generation = try await client.authManager.beginAuthenticationOperation()
    let operation = Task {
      try await client.authManager.save(
        tokens: migrationTokens("cancelled"), user: User(id: "user", username: "user"), generation: generation)
    }
    await #expect(throws: CancellationError.self) { try await operation.value }
    #expect(await store.rollbackWasCancelled == false)
    #expect(await store.writtenAccessTokens == ["cancelled", "accepted"])
    if !rollbackThrows {
      #expect(try await store.loadTokens() == initial)
    }
  }

  @Test(arguments: ["2026-09-04T12:00:00Z", "2026-09-04T12:00:00.125Z"])
  func dateDecodingRemainsSafeAcrossConcurrentConsumers(timestamp: String) async throws {
    let reference = Date(timeIntervalSince1970: 1_788_523_200)
    let fraction = timestamp.contains(".125") ? 0.125 : 0
    let data = Data("\"\(timestamp)\"".utf8)
    try await withThrowingTaskGroup(of: Date.self) { group in
      for _ in 0..<64 {
        group.addTask { try ArcaneJSON.makeDecoder().decode(Date.self, from: data) }
      }
      for try await date in group {
        #expect(abs(date.timeIntervalSince(reference) - fraction) < 0.001)
      }
    }
  }

  @Test @MainActor
  func mainActorConsumerRetainsCustomCredentialsAndProxy() async throws {
    try await verifyMigrationConsumer()
  }

  @Test @concurrent
  func concurrentConsumerRetainsCustomCredentialsAndProxy() async throws {
    try await verifyMigrationConsumer()
  }
}

private let migrationBaseURL = URL(string: "https://migration.example.test")!

private func migrationTokens(_ accessToken: String) -> TokenPair {
  TokenPair(accessToken: accessToken, refreshToken: "refresh", expiresAt: .distantFuture)
}

private func migrationClient(
  _ mock: MockURLProtocolSession,
  store: any TokenStore = InMemoryTokenStore(),
  proxy: (any ArcaneProxySession)? = nil
) -> ArcaneClient {
  ArcaneClient(configuration: .init(
    baseURL: migrationBaseURL, tokenStore: store, urlSession: mock.session(), proxySession: proxy))
}

private func migrationUploadFile() throws -> URL {
  let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try Data([0, 1, 2, 3, 255]).write(to: file)
  return file
}

private func migrationResponse(
  _ request: URLRequest, status: Int = 200, data: Data
) throws -> (HTTPURLResponse, Data) {
  let url = try #require(request.url)
  let response = try #require(HTTPURLResponse(
    url: url,
    statusCode: status,
    httpVersion: nil,
    headerFields: ["Content-Type": "application/json"]))
  return (response, data)
}

private func migrationUploadResponse(_ request: URLRequest) -> Data {
  let complete = request.httpMethod == "GET" || request.url?.path.hasSuffix("/chunks/1") == true
  let received = complete ? "[0,1]" : request.httpMethod == "PUT" ? "[0]" : "[]"
  return Data("""
    {"success":true,"data":{"id":"session","kind":"volume-backup","filename":"backup.tar",
    "size":5,"chunkSize":3,"totalChunks":2,"receivedChunks":\(received),"complete":\(complete),
    "createdAt":"2026-09-04T12:00:00Z"}}
    """.utf8)
}

private actor MigrationTokenStore: TokenStore {
  private var tokens: TokenPair?
  private let writeThrows: Bool
  private let rollbackThrows: Bool
  private(set) var rollbackWasCancelled: Bool?
  private(set) var writtenAccessTokens: [String] = []

  init(tokens: TokenPair, writeThrows: Bool = false, rollbackThrows: Bool = false) {
    self.tokens = tokens
    self.writeThrows = writeThrows
    self.rollbackThrows = rollbackThrows
  }

  func loadTokens() async throws -> TokenPair? { tokens }

  func saveTokens(_ tokens: TokenPair) async throws {
    writtenAccessTokens.append(tokens.accessToken)
    if tokens.accessToken == "cancelled" {
      self.tokens = tokens
      withUnsafeCurrentTask { $0?.cancel() }
      if writeThrows { try Task.checkCancellation() }
    } else {
      rollbackWasCancelled = Task.isCancelled
      try Task.checkCancellation()
      if rollbackThrows { throw ArcaneError.transport("Rollback failed") }
      self.tokens = tokens
    }
  }

  func clearTokens() async throws {
    try Task.checkCancellation()
    tokens = nil
  }
}

private actor MigrationProxySession: ArcaneProxySession {
  private(set) var generations: [UInt64] = []

  func requestContext(for url: URL) async -> ArcaneProxyRequestContext {
    .init(headers: ["Cookie": "proxy=migration"], generation: 64)
  }

  func receive(response: HTTPURLResponse, for url: URL, generation: UInt64) async {
    generations.append(generation)
  }
}

private func verifyMigrationConsumer(isolation: isolated (any Actor)? = #isolation) async throws {
  let mock = MockURLProtocolSession()
  let store = MigrationTokenStore(tokens: migrationTokens("custom"))
  let proxy = MigrationProxySession()
  let client = migrationClient(mock, store: store, proxy: proxy)
  await mock.setHandler { request in
    #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer custom")
    #expect(request.value(forHTTPHeaderField: "Cookie") == "proxy=migration")
    return try migrationResponse(request, data: Data(#"{"success":true,"data":"response"}"#.utf8))
  }
  let response: String = try await client.transport.request("migration")
  #expect(response == "response")
  #expect(await proxy.generations == [64])
  #expect(await mock.requestCount() == 1)
}
