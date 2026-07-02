@testable import Arcane
import Foundation
import XCTest

/// Reverse-proxy (Traefik ForwardAuth / Authelia) handling: a proxy 401 must be
/// classified as `.externalAuth` — distinct from a genuine Arcane `.unauthorized`
/// — and must NOT wipe stored Arcane tokens.
final class ExternalAuthTests: XCTestCase {
    private let base = URL(string: "https://arcane.example.com")!
    private let decoder = ArcaneJSON.makeDecoder()

    // MARK: - ArcaneError.from classification

    func testGenuineArcane401MapsToUnauthorized() {
        let data = Data(#"{"success":false,"error":"invalid credentials","code":"UNAUTHORIZED"}"#.utf8)
        XCTAssertEqual(ArcaneError.from(statusCode: 401, data: data, headers: [:], decoder: decoder), .unauthorized)
    }

    func testHuma401MapsToUnauthorized() {
        let data = Data(#"{"title":"Unauthorized","status":401,"detail":"token expired"}"#.utf8)
        XCTAssertEqual(ArcaneError.from(statusCode: 401, data: data, headers: [:], decoder: decoder), .unauthorized)
    }

    func testProxyHTML401MapsToExternalAuth() {
        let data = Data("<html><body>Authelia sign in</body></html>".utf8)
        let error = ArcaneError.from(statusCode: 401, data: data, headers: ["Content-Type": "text/html"], decoder: decoder)
        XCTAssertEqual(error, .externalAuth)
    }

    func testEmptyBody401MapsToExternalAuth() {
        XCTAssertEqual(ArcaneError.from(statusCode: 401, data: Data(), headers: [:], decoder: decoder), .externalAuth)
    }

    // MARK: - Transport token-clear behavior

    func testTransportKeepsTokensAndDoesNotRefreshOnExternalAuth401() async throws {
        await MockURLProtocol.reset()
        let session = makeMockURLSession()
        let tokens = TokenPair(accessToken: "access", refreshToken: "refresh", expiresAt: Date(timeIntervalSince1970: 1))
        let store = InMemoryTokenStore(tokens: tokens)
        let transport = makeTransport(session: session, store: store)

        await MockURLProtocol.setHandler { request in
            let response = try XCTUnwrap(HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 401,
                httpVersion: nil,
                headerFields: ["Content-Type": "text/html"]
            ))
            return (response, Data("<html>Authelia</html>".utf8))
        }

        do {
            _ = try await transport.rawRequest("auth/me", body: Optional<EmptyBody>.none)
            XCTFail("Expected the request to fail")
        } catch {
            XCTAssertEqual(error as? ArcaneError, .externalAuth)
        }

        // Tokens survive, and no pointless refresh was attempted (single request).
        let stored = try await store.loadTokens()
        XCTAssertEqual(stored, tokens)
        let requestCount = await MockURLProtocol.requestCount()
        XCTAssertEqual(requestCount, 1)
    }

    func testTransportClearsTokensOnGenuine401() async throws {
        await MockURLProtocol.reset()
        let session = makeMockURLSession()
        // Empty refresh token → no refresh attempt, so the 401 hits the transport's
        // own clear path directly.
        let store = InMemoryTokenStore(tokens: TokenPair(accessToken: "access", refreshToken: "", expiresAt: Date(timeIntervalSince1970: 1)))
        let transport = makeTransport(session: session, store: store)

        await MockURLProtocol.setHandler { request in
            let response = try XCTUnwrap(HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 401,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            return (response, Data(#"{"error":"invalid token","code":"UNAUTHORIZED"}"#.utf8))
        }

        do {
            _ = try await transport.rawRequest("auth/me", body: Optional<EmptyBody>.none)
            XCTFail("Expected the request to fail")
        } catch {
            XCTAssertEqual(error as? ArcaneError, .unauthorized)
        }

        let stored = try await store.loadTokens()
        XCTAssertNil(stored)
    }

    // MARK: - Helpers

    private func makeMockURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func makeTransport(session: URLSession, store: InMemoryTokenStore) -> ArcaneURLSessionTransport {
        let authManager = AuthManager(
            baseURL: base,
            tokenStore: store,
            apiKey: nil,
            urlSession: session,
            decoder: ArcaneJSON.makeDecoder(),
            encoder: ArcaneJSON.makeEncoder()
        )
        return ArcaneURLSessionTransport(
            baseURL: base,
            session: session,
            authManager: authManager,
            retryPolicy: RetryPolicy(maxAttempts: 1, baseBackoff: .milliseconds(1), maxBackoff: .milliseconds(1)),
            decoder: ArcaneJSON.makeDecoder(),
            encoder: ArcaneJSON.makeEncoder()
        )
    }
}
