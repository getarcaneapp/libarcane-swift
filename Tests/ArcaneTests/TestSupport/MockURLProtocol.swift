import Foundation

actor MockURLProtocolHandlerStore {
  typealias Handler = @Sendable (URLRequest) async throws -> (HTTPURLResponse, Data)

  private var handler: Handler?
  private var requestCount = 0

  func reset() {
    handler = nil
    requestCount = 0
  }

  func setHandler(_ handler: @escaping Handler) {
    self.handler = handler
  }

  func handle(_ request: URLRequest) async throws -> (HTTPURLResponse, Data) {
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

  static func reset() async {
    await store.reset()
  }

  static func setHandler(
    _ handler: @escaping @Sendable (URLRequest) async throws -> (HTTPURLResponse, Data)
  ) async {
    await store.setHandler(handler)
  }

  static func requestCount() async -> Int {
    await store.recordedRequestCount()
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
    Task {
      do {
        let (response, data) = try await Self.store.handle(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
      } catch {
        client?.urlProtocol(self, didFailWithError: error)
      }
    }
  }

  override func stopLoading() {}
}
