import Foundation

final class OIDCMockURLProtocol: URLProtocol, @unchecked Sendable {
  private static let lock = NSLock()
  nonisolated(unsafe) private static var recordedCallbackRequestCount = 0

  static var callbackRequestCount: Int {
    lock.withLock { recordedCallbackRequestCount }
  }

  static func reset() {
    lock.withLock {
      recordedCallbackRequestCount = 0
    }
  }

  override class func canInit(with request: URLRequest) -> Bool {
    true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    guard let url = request.url, url.path.hasSuffix("/api/oidc/callback") else {
      client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
      return
    }

    Self.lock.withLock {
      Self.recordedCallbackRequestCount += 1
    }

    guard
      let response = HTTPURLResponse(
        url: url,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )
    else {
      client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
      return
    }

    let data = Data(
      #"""
      {
        "success": true,
        "token": "access-token",
        "refreshToken": "refresh-token",
        "expiresAt": "2026-07-25T12:00:00Z",
        "user": {
          "id": "oidc-user-id",
          "username": "oidc-user",
          "roles": []
        }
      }
      """#.utf8
    )
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: data)
    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}
}
