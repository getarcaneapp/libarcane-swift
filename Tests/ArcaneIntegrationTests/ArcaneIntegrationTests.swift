import XCTest
import Arcane

final class ArcaneIntegrationTests: XCTestCase {
    func testBackendHealthWhenConfigured() async throws {
        guard let rawURL = ProcessInfo.processInfo.environment["ARCANE_TEST_URL"],
              let url = URL(string: rawURL) else {
            throw XCTSkip("Set ARCANE_TEST_URL to run integration tests")
        }
        let client = ArcaneClient(configuration: .init(baseURL: url, tokenStore: InMemoryTokenStore()))
        let _: AnyDecodable = try await client.rest.get("health")
    }
}
