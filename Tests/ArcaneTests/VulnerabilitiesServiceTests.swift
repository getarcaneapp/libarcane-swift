import Foundation
import Testing

@testable import Arcane

@Suite(.serialized) struct VulnerabilitiesServiceTests {
  @Test func overviewUsesEnvironmentRouteAndDecodesRankings() async throws {
    await MockURLProtocol.reset()
    await MockURLProtocol.setHandler { request in
      #expect(request.httpMethod == "GET")
      #expect(request.url?.path == "/api/environments/testing/vulnerabilities/overview")
      let body = #"""
        {
          "success": true,
          "data": {
            "riskScore": 72,
            "riskBand": "high",
            "scoreStatus": "complete",
            "delta7d": -3,
            "trend": [{"date": "2026-09-28", "riskScore": 72}],
            "drivers": {
              "knownExploited": 1, "overdueKnownExploited": 0, "highEpss": 2,
              "exposedCriticalHigh": 3, "fixable": 4, "findings": 5,
              "imagesScanned": 2, "imagesTotal": 3, "scoredImages": 2
            },
            "summary": {"critical": 1, "high": 2, "medium": 1, "low": 1, "unknown": 0, "total": 5},
            "exposure": {"running": 3, "stopped": 1, "unused": 1, "unknown": 0},
            "scoreDriver": {
              "vulnerabilityId": "CVE-2026-1", "imageName": "app:latest",
              "pkgName": "openssl", "fixedVersion": "3.0.1", "knownExploited": true
            },
            "riskiestImages": [{
              "imageId": "sha256:123", "imageName": "app:latest", "riskScore": 72,
              "riskBand": "high", "scoreStatus": "complete", "exposure": "running",
              "runningContainers": 1, "knownExploited": 1, "findings": 5
            }],
            "riskiestFindings": [{
              "vulnerabilityId": "CVE-2026-1", "pkgName": "openssl", "severity": "HIGH",
              "cvss": 7.5, "risk": 8.2, "knownExploited": true,
              "ransomware": false, "imagesAffected": 2
            }],
            "prevalentFindings": [],
            "threatIntel": {"enabled": true, "lastSyncedAt": "2026-09-28T12:00:00Z", "stale": false}
          }
        }
        """#
      let response = try #require(HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]))
      return (response, Data(body.utf8))
    }

    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    let client = ArcaneClient(configuration: .init(
      baseURL: URL(string: "https://vulnerability-contract.example")!,
      urlSession: URLSession(configuration: configuration)))

    let overview = try await client.vulnerabilities.riskOverview(envID: .init(rawValue: "testing"))
    #expect(overview.riskScore == 72)
    #expect(overview.delta7d == -3)
    #expect(overview.scoreDriver?.vulnerabilityId == "CVE-2026-1")
    #expect(overview.riskiestImages.first?.id == "sha256:123")
    #expect(overview.riskiestFindings.first?.risk == 8.2)
    #expect(overview.threatIntel.lastSyncedAt != nil)
  }

  @Test func unignoreAcceptsEmptyResponse() async throws {
    await MockURLProtocol.reset()
    await MockURLProtocol.setHandler { request in
      #expect(request.httpMethod == "DELETE")
      #expect(request.url?.path == "/api/environments/testing/vulnerabilities/ignore/ignore-1")
      let response = try #require(HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]))
      return (response, Data(#"{"success":true,"data":{}}"#.utf8))
    }

    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    let client = ArcaneClient(configuration: .init(
      baseURL: URL(string: "https://vulnerability-contract.example")!,
      urlSession: URLSession(configuration: configuration)))

    try await client.vulnerabilities.unignore(envID: .init(rawValue: "testing"), ignoreId: "ignore-1")
  }
}
