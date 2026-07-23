import Foundation
import XCTest

@testable import Arcane

final class VariableModelsTests: XCTestCase {
  private let decoder = ArcaneJSON.makeDecoder()
  private let encoder = ArcaneJSON.makeEncoder()

  func testDecodeGlobalVariableUsesBackendFieldNamesAndDefaults() throws {
    let variable = try decoder.decode(
      GlobalVariable.self,
      from: Data(
        #"{"id":"var_1","key":"TOKEN","isSecret":true,"allEnvironments":false,"environmentIds":["0","edge_1"],"createdAt":"2026-07-20T12:00:00Z"}"#
          .utf8
      )
    )

    XCTAssertEqual(variable.id, "var_1")
    XCTAssertEqual(variable.key, "TOKEN")
    XCTAssertEqual(variable.value, "")
    XCTAssertTrue(variable.isSecret)
    XCTAssertFalse(variable.allEnvironments)
    XCTAssertEqual(variable.environmentIDs, ["0", "edge_1"])
    XCTAssertNil(variable.updatedAt)
  }

  func testVariableSyncStatePreservesFutureAndMissingValues() throws {
    let statuses = try decoder.decode(
      [EnvironmentSyncStatus].self,
      from: Data(
        #"[{"environmentId":"0","environmentName":"Local","status":"pending"},{"environmentId":"edge_1","status":"queued"},{"environmentId":"edge_2"}]"#
          .utf8
      )
    )

    XCTAssertEqual(statuses[0].status, .pending)
    XCTAssertEqual(statuses[1].status, .unknown("queued"))
    XCTAssertEqual(statuses[2].status, .unknown(""))
  }

  func testMutationResponseDefaultsMissingSyncResults() throws {
    let response = try decoder.decode(
      GlobalVariableMutationResponse.self,
      from: Data(#"{}"#.utf8)
    )

    XCTAssertNil(response.variable)
    XCTAssertTrue(response.syncResults.isEmpty)
  }

  func testUpdateRequestDistinguishesNilFromEmptyEnvironmentIDs() throws {
    let data = try encoder.encode(UpdateGlobalVariableRequest(environmentIDs: []))
    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    XCTAssertNotNil(object["environmentIds"] as? [String])
    XCTAssertNil(object["value"])
  }

  func testCreateRequestEncodesManagerVariableScopeKeys() throws {
    let data = try encoder.encode(
      CreateGlobalVariableRequest(
        key: "REGION",
        value: "us-central",
        allEnvironments: false,
        environmentIDs: ["edge_1"]
      )
    )
    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    XCTAssertEqual(object["key"] as? String, "REGION")
    XCTAssertEqual(object["environmentIds"] as? [String], ["edge_1"])
    XCTAssertEqual(object["allEnvironments"] as? Bool, false)
  }
}
