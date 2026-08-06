import Foundation
import XCTest

@testable import ArcanePasskeys

@MainActor
final class ArcanePasskeyAuthenticatorTests: XCTestCase {
  private let state = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"

  func testParsesExactSuccessCallback() throws {
    let credential = Data(#"{"id":"credential","type":"public-key"}"#.utf8)
      .base64URLEncodedString()
    let url = try XCTUnwrap(
      URL(string: "arcane-mobile://passkey-callback?state=\(state)&response=\(credential)"))

    let parsed = try ArcanePasskeyAuthenticator.parseCallback(url, expectedState: state)
    XCTAssertEqual(parsed["id"]?.stringValue, "credential")
  }

  func testRejectsWrongStateOriginAndDuplicateItems() throws {
    let response = Data(#"{"id":"credential"}"#.utf8).base64URLEncodedString()
    let wrongState = try XCTUnwrap(
      URL(string: "arcane-mobile://passkey-callback?state=wrong&response=\(response)"))
    XCTAssertThrowsError(
      try ArcanePasskeyAuthenticator.parseCallback(wrongState, expectedState: state)
    ) { error in
      XCTAssertEqual(error as? ArcanePasskeyAuthenticator.CeremonyError, .stateMismatch)
    }

    let wrongOrigin = try XCTUnwrap(
      URL(string: "https://example.com/passkey-callback?state=\(state)&response=\(response)"))
    XCTAssertThrowsError(
      try ArcanePasskeyAuthenticator.parseCallback(wrongOrigin, expectedState: state)
    )

    let duplicate = try XCTUnwrap(
      URL(
        string:
          "arcane-mobile://passkey-callback?state=\(state)&state=\(state)&response=\(response)"))
    XCTAssertThrowsError(
      try ArcanePasskeyAuthenticator.parseCallback(duplicate, expectedState: state)
    ) { error in
      XCTAssertEqual(error as? ArcanePasskeyAuthenticator.CeremonyError, .duplicateCallbackItem)
    }
  }

  func testAcceptsHTTPSAndLoopbackHTTPOriginsOnly() throws {
    XCTAssertEqual(
      ArcanePasskeyAuthenticator.serverOrigin(
        from: try XCTUnwrap(URL(string: "https://arcane.example/api")))?.absoluteString,
      "https://arcane.example/"
    )
    XCTAssertNotNil(
      ArcanePasskeyAuthenticator.serverOrigin(
        from: try XCTUnwrap(URL(string: "http://127.0.0.1:3552/api"))))
    XCTAssertNil(
      ArcanePasskeyAuthenticator.serverOrigin(
        from: try XCTUnwrap(URL(string: "http://arcane.example/api"))))
  }

  func testDuplicateCompletionUsesOnlyFirstCallback() async throws {
    let callback = ArcanePasskeyAuthenticator.makeCallbackStream()
    let first = try XCTUnwrap(
      URL(string: "arcane-mobile://passkey-callback?state=first&error=failed"))
    let second = try XCTUnwrap(
      URL(string: "arcane-mobile://passkey-callback?state=second&error=failed"))
    callback.completionHandler(first, nil)
    callback.completionHandler(second, nil)

    let result = try await ArcanePasskeyAuthenticator.awaitCallback(
      stream: callback.stream,
      start: { true },
      cancel: {}
    )
    XCTAssertEqual(result, first)
  }

  func testMapsBridgeCancellationToStructuredCancellation() throws {
    let url = try XCTUnwrap(
      URL(string: "arcane-mobile://passkey-callback?state=\(state)&error=cancelled"))
    XCTAssertThrowsError(
      try ArcanePasskeyAuthenticator.parseCallback(url, expectedState: state)
    ) { error in
      XCTAssertEqual(error as? ArcanePasskeyAuthenticator.CeremonyError, .cancelled)
    }
  }
}

extension Data {
  fileprivate func base64URLEncodedString() -> String {
    base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}
