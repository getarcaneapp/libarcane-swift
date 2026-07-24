import Foundation

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

  func reset() {
    handler = nil
    requestCount = 0
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

  func recordedRequestCount() -> Int {
    requestCount
  }
}

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
  private static let store = MockURLProtocolHandlerStore()
  private static let stopLoadingLock = NSLock()
  nonisolated(unsafe) private static var recordedStopLoadingCount = 0
  private var loadingTask: Task<Void, Never>?

  static func reset() async {
    await store.reset()
    resetRecordedStopLoadingCount()
  }

  static func setHandler(
    _ handler: @escaping @Sendable (URLRequest) async throws -> (HTTPURLResponse, Data)
  ) async {
    await store.setHandler { request in
      let (response, data) = try await handler(request)
      return .complete(response, data)
    }
  }

  static func setStreamingHandler(
    _ handler: @escaping @Sendable (URLRequest) async throws -> MockURLProtocolStreamResponse
  ) async {
    await store.setHandler { request in
      let result = try await handler(request)
      return .stream(result.response, chunks: result.chunks, holdOpen: result.holdOpen)
    }
  }

  static func requestCount() async -> Int {
    await store.recordedRequestCount()
  }

  static func stopLoadingCount() async -> Int {
    recordedStopCount()
  }

  private static func resetRecordedStopLoadingCount() {
    stopLoadingLock.lock()
    recordedStopLoadingCount = 0
    stopLoadingLock.unlock()
  }

  private static func recordedStopCount() -> Int {
    stopLoadingLock.lock()
    defer { stopLoadingLock.unlock() }
    return recordedStopLoadingCount
  }

  // swiftlint:disable static_over_final_class
  override class func canInit(with request: URLRequest) -> Bool {
    true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }
  // swiftlint:enable static_over_final_class

  override func startLoading() {
    loadingTask = Task {
      do {
        let result = try await Self.store.handle(request)
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
          do {
            try await Task.sleep(for: .seconds(3_600))
          } catch {
            return
          }
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
    Self.stopLoadingLock.lock()
    Self.recordedStopLoadingCount += 1
    Self.stopLoadingLock.unlock()
  }
}
