import XCTest
import Foundation
@testable import Arcane

final class ArcaneTests: XCTestCase {
    func testEnvironmentIDLiteral() {
        let id: EnvironmentID = "3"
        XCTAssertEqual(id.rawValue, "3")
        XCTAssertEqual(EnvironmentID.localDocker.rawValue, "0")
    }

    func testErrorMapping() {
        let data = #"{"code":"CONFLICT","message":"already exists"}"#.data(using: .utf8)!
        let error = ArcaneError.from(statusCode: 409, data: data, headers: [:], decoder: ArcaneJSON.makeDecoder())
        XCTAssertEqual(error, .conflict(message: "already exists"))
    }
}
