import Foundation
import Synchronization

final class OIDCMockURLProtocol: URLProtocol, @unchecked Sendable {
  private static let recordedCallbackRequestCount = Mutex(0)

  static var callbackRequestCount: Int {
    recordedCallbackRequestCount.withLock { $0 }
  }

  static func reset() {
    recordedCallbackRequestCount.withLock {
      $0 = 0
    }
  }

  override static func canInit(with request: URLRequest) -> Bool {
    true
  }

  override static func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    if let url = request.url, url.path.hasSuffix("/api/oidc/url"),
      let response = HTTPURLResponse(
        url: url,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      ) {
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: Data(#"{"success":true,"authUrl":"https://idp.example.com/authorize"}"#.utf8))
      client?.urlProtocolDidFinishLoading(self)
      return
    }
    guard let url = request.url, url.path.hasSuffix("/api/oidc/callback") else {
      client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
      return
    }

    Self.recordedCallbackRequestCount.withLock {
      $0 += 1
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
