import Foundation
import XCTest

@testable import Arcane

final class TransportAuthenticationTests: XCTestCase {
  private let mock = MockURLProtocolSession()
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

    await mock.reset()
    let session = mock.session()
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

    await mock.setHandler { request in
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
    let requestCount = await mock.requestCount()
    let storedTokens = try await store.loadTokens()

    XCTAssertEqual(requestCount, 1)
    XCTAssertEqual(firstTokens, refreshedTokens)
    XCTAssertEqual(secondTokens, refreshedTokens)
    XCTAssertEqual(storedTokens, refreshedTokens)
  }

  func testRefreshTokensKeepsStoredTokensOnTransientServerFailure() async throws {
    await mock.reset()
    let session = mock.session()
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

    await mock.setHandler { request in
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
      guard case ArcaneError.server(let code, let message) = error else {
        return XCTFail("Expected server error, got \(error)")
      }
      XCTAssertEqual(code, "HTTP_503")
      XCTAssertEqual(message, "try again later")
    }

    let storedTokens = try await store.loadTokens()
    XCTAssertEqual(storedTokens, originalTokens)
  }

  func testAuthenticationHeadersProactivelyRefreshExpiredToken() async throws {
    struct ResponseEnvelope: Encodable {
      let success: Bool
      let data: TokenRefreshResponse
    }

    await mock.reset()
    let session = mock.session()
    let expiredTokens = TokenPair(
      accessToken: "expired-access-token",
      refreshToken: "refresh-token",
      expiresAt: Date(timeIntervalSinceNow: -60)
    )
    // Whole seconds: the pair round-trips through JSON, which drops
    // sub-millisecond precision and would fail an exact Date comparison.
    let refreshedTokens = TokenPair(
      accessToken: "fresh-access-token",
      refreshToken: "fresh-refresh-token",
      expiresAt: Date(timeIntervalSince1970: Date().timeIntervalSince1970.rounded() + 3600)
    )
    let store = InMemoryTokenStore(tokens: expiredTokens)
    let authManager = AuthManager(
      baseURL: URL(string: "https://arcane.example.com")!,
      tokenStore: store,
      apiKey: nil,
      urlSession: session,
      decoder: ArcaneJSON.makeDecoder(),
      encoder: ArcaneJSON.makeEncoder()
    )

    await mock.setHandler { request in
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
      return (response, try ArcaneJSON.makeEncoder().encode(envelope))
    }

    let headers = try await authManager.authenticationHeaders()
    let requestCount = await mock.requestCount()
    let storedTokens = try await store.loadTokens()

    XCTAssertEqual(requestCount, 1)
    XCTAssertEqual(headers["Authorization"], "Bearer \(refreshedTokens.accessToken)")
    XCTAssertEqual(storedTokens, refreshedTokens)
  }

  func testAuthenticationHeadersFallBackToStaleTokenWhenRefreshFails() async throws {
    await mock.reset()
    let session = mock.session()
    let expiredTokens = TokenPair(
      accessToken: "expired-access-token",
      refreshToken: "refresh-token",
      expiresAt: Date(timeIntervalSinceNow: -60)
    )
    let store = InMemoryTokenStore(tokens: expiredTokens)
    let authManager = AuthManager(
      baseURL: URL(string: "https://arcane.example.com")!,
      tokenStore: store,
      apiKey: nil,
      urlSession: session,
      decoder: ArcaneJSON.makeDecoder(),
      encoder: ArcaneJSON.makeEncoder()
    )

    await mock.setHandler { request in
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

    let headers = try await authManager.authenticationHeaders()
    let firstRequestCount = await mock.requestCount()
    XCTAssertEqual(headers["Authorization"], "Bearer \(expiredTokens.accessToken)")
    XCTAssertEqual(firstRequestCount, 1)

    // A failed proactive refresh is throttled: an immediate follow-up call
    // must not hit the refresh endpoint again.
    let secondHeaders = try await authManager.authenticationHeaders()
    let secondRequestCount = await mock.requestCount()
    XCTAssertEqual(secondHeaders["Authorization"], "Bearer \(expiredTokens.accessToken)")
    XCTAssertEqual(secondRequestCount, 1)
  }

  func testAuthenticationHeadersDoNotRefreshValidToken() async throws {
    await mock.reset()
    let session = mock.session()
    let validTokens = TokenPair(
      accessToken: "valid-access-token",
      refreshToken: "refresh-token",
      expiresAt: Date(timeIntervalSinceNow: 3600)
    )
    let authManager = AuthManager(
      baseURL: URL(string: "https://arcane.example.com")!,
      tokenStore: InMemoryTokenStore(tokens: validTokens),
      apiKey: nil,
      urlSession: session,
      decoder: ArcaneJSON.makeDecoder(),
      encoder: ArcaneJSON.makeEncoder()
    )

    await mock.setHandler { _ in
      XCTFail("No network request expected for a non-expired token")
      throw ArcaneError.transport("unexpected request")
    }

    let headers = try await authManager.authenticationHeaders()
    let requestCount = await mock.requestCount()
    XCTAssertEqual(headers["Authorization"], "Bearer \(validTokens.accessToken)")
    XCTAssertEqual(requestCount, 0)
  }

}
