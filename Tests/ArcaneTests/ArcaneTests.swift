import Foundation
import XCTest

@testable import Arcane

final class ArcaneTests: XCTestCase {
  func testEnvironmentIDLiteral() {
    let id: EnvironmentID = "3"
    XCTAssertEqual(id.rawValue, "3")
    XCTAssertEqual(EnvironmentID.localDocker.rawValue, "0")
  }

  func testErrorMapping() {
    let data = Data(#"{"code":"CONFLICT","message":"already exists"}"#.utf8)
    let error = ArcaneError.from(
      statusCode: 409, data: data, headers: [:], decoder: ArcaneJSON.makeDecoder())
    XCTAssertEqual(error, .conflict(message: "already exists"))
  }

  func testHuma422ValidationMapping() {
    let json = #"""
      {
          "$schema": "https://example.com/schemas/ErrorModel.json",
          "title": "Unprocessable Entity",
          "status": 422,
          "detail": "validation failed",
          "errors": [
              { "message": "expected string", "location": "body.username", "value": null },
              { "message": "must be at least 8 characters", "location": "body.password", "value": null }
          ]
      }
      """#
    let error = ArcaneError.from(
      statusCode: 422, data: Data(json.utf8), headers: [:], decoder: ArcaneJSON.makeDecoder())
    guard case .validation(let fields) = error else {
      return XCTFail("Expected .validation case, got \(error)")
    }
    XCTAssertEqual(fields["username"], ["expected string"])
    XCTAssertEqual(fields["password"], ["must be at least 8 characters"])
  }

  func testHuma422WithoutErrorsFallsBackToServer() {
    let json = #"""
      { "$schema": "https://example.com/schemas/ErrorModel.json", "title": "Unprocessable Entity", "status": 422, "detail": "bad input" }
      """#
    let error = ArcaneError.from(
      statusCode: 422, data: Data(json.utf8), headers: [:], decoder: ArcaneJSON.makeDecoder())
    guard case .server(_, let message) = error else {
      return XCTFail("Expected .server case, got \(error)")
    }
    XCTAssertEqual(message, "bad input")
  }
}
