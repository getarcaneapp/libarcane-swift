import Foundation
import XCTest

@testable import Arcane

final class EnvironmentUpdateJobTests: XCTestCase {
  private let decoder = ArcaneJSON.makeDecoder()

  func testDecodeFullJob() throws {
    let json = #"""
      {
          "id": "job_1",
          "createdAt": "2026-07-07T10:00:00Z",
          "updatedAt": "2026-07-07T10:02:30Z",
          "status": "pending_restart",
          "userId": "u_1",
          "username": "admin",
          "managerVersionAtStart": "1.5.0",
          "managerDigestAtStart": "sha256:abc",
          "managerTargetVersion": "1.6.0",
          "results": [
              {
                  "environmentId": "0",
                  "environmentName": "Manager",
                  "status": "updating",
                  "fromVersion": "1.5.0",
                  "toVersion": "1.6.0"
              },
              {
                  "environmentId": "env_2",
                  "environmentName": "Edge Node",
                  "status": "skipped_offline"
              },
              {
                  "environmentId": "env_3",
                  "environmentName": "Lab",
                  "status": "failed",
                  "error": "pull failed"
              },
              {
                  "environmentId": "env_4",
                  "environmentName": "Current",
                  "status": "up_to_date"
              }
          ]
      }
      """#

    let job = try decoder.decode(EnvironmentUpdateJob.self, from: Data(json.utf8))
    XCTAssertEqual(job.id, "job_1")
    XCTAssertEqual(job.status, .pendingRestart)
    XCTAssertFalse(job.isTerminal)
    XCTAssertEqual(job.managerTargetVersion, "1.6.0")
    XCTAssertEqual(job.results?.count, 4)
    XCTAssertEqual(job.managerResult?.status, .updating)
    XCTAssertEqual(job.managerResult?.toVersion, "1.6.0")
    XCTAssertEqual(job.results?[1].status, .skippedOffline)
    XCTAssertEqual(job.results?[2].error, "pull failed")
    XCTAssertEqual(job.results?[3].status, .upToDate)
  }

  func testDecodeMinimalJobAndTerminalStates() throws {
    let json = #"""
      { "id": "job_2", "status": "completed" }
      """#
    let job = try decoder.decode(EnvironmentUpdateJob.self, from: Data(json.utf8))
    XCTAssertEqual(job.status, .completed)
    XCTAssertTrue(job.isTerminal)
    XCTAssertNil(job.results)
    XCTAssertNil(job.managerResult)

    let failed = try decoder.decode(
      EnvironmentUpdateJob.self, from: Data(#"{ "id": "job_3", "status": "failed" }"#.utf8))
    XCTAssertTrue(failed.isTerminal)
  }

  func testUnknownStatusesFallBackInsteadOfThrowing() throws {
    let json = #"""
      {
          "id": "job_4",
          "status": "some_future_state",
          "results": [
              { "environmentId": "env_1", "environmentName": "A", "status": "brand_new" }
          ]
      }
      """#
    let job = try decoder.decode(EnvironmentUpdateJob.self, from: Data(json.utf8))
    XCTAssertEqual(job.status, .unknown)
    XCTAssertFalse(job.isTerminal)
    XCTAssertEqual(job.results?.first?.status, .unknown)
  }
}
