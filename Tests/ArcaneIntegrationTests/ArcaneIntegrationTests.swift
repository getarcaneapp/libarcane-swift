import Arcane
import XCTest

final class ArcaneIntegrationTests: XCTestCase {
  func testBackendHealthWhenConfigured() async throws {
    guard let rawURL = ProcessInfo.processInfo.environment["ARCANE_TEST_URL"],
      let url = URL(string: rawURL)
    else {
      throw XCTSkip("Set ARCANE_TEST_URL to run integration tests")
    }
    let client = ArcaneClient(configuration: .init(baseURL: url, tokenStore: InMemoryTokenStore()))
    // Health returns an unwrapped status object on current backends.
    let data = try await client.transport.rawRequest(
      "health", method: "GET", body: Optional<String>.none, authorized: false)
    _ = try ArcaneJSON.makeDecoder().decode(AnyDecodable.self, from: data)
  }
}
