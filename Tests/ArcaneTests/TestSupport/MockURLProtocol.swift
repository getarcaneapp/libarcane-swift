import Foundation
import Testing

@testable import Arcane

enum MockURLProtocolResult: Sendable {
  case complete(HTTPURLResponse, Data)
  case stream(HTTPURLResponse, chunks: [Data], holdOpen: Bool)
}

struct MockURLProtocolStreamResponse: Sendable {
  let response: HTTPURLResponse
  let chunks: [Data]
  let holdOpen: Bool
}

actor MockURLProtocolHandlerStore {
  typealias Handler = @Sendable (URLRequest) async throws -> MockURLProtocolResult

  private var handler: Handler?
  private var requestCount = 0
  private var stopLoadingCount = 0

  func reset() {
    handler = nil
    requestCount = 0
    stopLoadingCount = 0
  }

  func setHandler(_ handler: @escaping Handler) {
    self.handler = handler
  }

  func handle(_ request: URLRequest) async throws -> MockURLProtocolResult {
    requestCount += 1
    guard let handler else {
      throw URLError(.badServerResponse)
    }
    return try await handler(request)
  }

  func recordStopLoading() { stopLoadingCount += 1 }
  func recordedStopLoadingCount() -> Int { stopLoadingCount }

  func recordedRequestCount() -> Int {
    requestCount
  }
}

/// Each test owns a scope; the session header selects its transport state.
/// The registry only routes requests and never shares handlers or counters.
final class MockURLProtocolSession: Sendable {
  private let id = UUID().uuidString
  private let store = MockURLProtocolHandlerStore()

  init() { MockURLProtocol.registry.register(store, id: id) }
  deinit { MockURLProtocol.registry.remove(id: id) }

  func session(configuration: URLSessionConfiguration = .ephemeral) -> URLSession {
    configuration.protocolClasses = [MockURLProtocol.self]
    var headers = configuration.httpAdditionalHeaders ?? [:]
    headers[MockURLProtocol.scopeHeader] = id
    configuration.httpAdditionalHeaders = headers
    return URLSession(configuration: configuration)
  }

  func reset() async { await store.reset() }

  func setHandler(
    _ handler: @escaping @Sendable (URLRequest) async throws -> (HTTPURLResponse, Data)
  ) async {
    await store.setHandler { request in
      let (response, data) = try await handler(request)
      return .complete(response, data)
    }
  }

  func setStreamingHandler(
    _ handler: @escaping @Sendable (URLRequest) async throws -> MockURLProtocolStreamResponse
  ) async {
    await store.setHandler { request in
      let result = try await handler(request)
      return .stream(result.response, chunks: result.chunks, holdOpen: result.holdOpen)
    }
  }

  func requestCount() async -> Int { await store.recordedRequestCount() }
  func stopLoadingCount() async -> Int { await store.recordedStopLoadingCount() }
}

final class MockURLProtocolRegistry: @unchecked Sendable {
  private let lock = NSLock()
  private var stores: [String: MockURLProtocolHandlerStore] = [:]

  func register(_ store: MockURLProtocolHandlerStore, id: String) {
    lock.lock()
    defer { lock.unlock() }
    stores[id] = store
  }

  func remove(id: String) {
    lock.lock()
    defer { lock.unlock() }
    stores.removeValue(forKey: id)
  }

  func store(for id: String?) -> MockURLProtocolHandlerStore? {
    lock.lock()
    defer { lock.unlock() }
    return id.flatMap { stores[$0] }
  }
}

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
  static let registry = MockURLProtocolRegistry()
  static let scopeHeader = "X-Arcane-Test-Scope"
  private var loadingTask: Task<Void, Never>?
  private var store: MockURLProtocolHandlerStore?

  // swiftlint:disable static_over_final_class
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  // swiftlint:enable static_over_final_class

  override func startLoading() {
    let store = Self.registry.store(for: request.value(forHTTPHeaderField: Self.scopeHeader))
    self.store = store
    loadingTask = Task {
      do {
        guard let store else { throw URLError(.badServerResponse) }
        let result = try await store.handle(request)
        let response: HTTPURLResponse
        let chunks: [Data]
        let holdOpen: Bool
        switch result {
        case .complete(let completedResponse, let data):
          response = completedResponse
          chunks = [data]
          holdOpen = false
        case .stream(let streamingResponse, let streamingChunks, let shouldHoldOpen):
          response = streamingResponse
          chunks = streamingChunks
          holdOpen = shouldHoldOpen
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        for chunk in chunks {
          guard !Task.isCancelled else { return }
          client?.urlProtocol(self, didLoad: chunk)
          await Task.yield()
        }
        if holdOpen {
          do { try await Task.sleep(for: .seconds(3_600)) } catch { return }
        }
        guard !Task.isCancelled else { return }
        client?.urlProtocolDidFinishLoading(self)
      } catch {
        guard !Task.isCancelled else { return }
        client?.urlProtocol(self, didFailWithError: error)
      }
    }
  }

  override func stopLoading() {
    loadingTask?.cancel()
    loadingTask = nil
    if let store { Task { await store.recordStopLoading() } }
  }
}

func mockRequestBody(_ request: URLRequest) throws -> Data {
  if let data = request.httpBody { return data }
  let stream = try #require(request.httpBodyStream)
  stream.open()
  defer { stream.close() }
  var result = Data()
  var bytes = [UInt8](repeating: 0, count: 4096)
  while true {
    let count = stream.read(&bytes, maxLength: bytes.count)
    guard count >= 0 else { throw ArcaneError.transport("Unable to read test request") }
    if count == 0 { return result }
    result.append(bytes, count: count)
  }
}
