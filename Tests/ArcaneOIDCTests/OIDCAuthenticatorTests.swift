import Foundation
import Testing

import Arcane
@testable import ArcaneOIDC

@Suite("OIDC authenticator")
@MainActor
struct OIDCAuthenticatorTests {
  private nonisolated enum CallbackError: Error {
    case expected
  }

  @Test
  func testDuplicateSuccessCallbacksReturnFirstURL() async throws {
    let firstURL = try #require(
      URL(string: "arcane-mobile://oidc-callback?code=first&state=state"))
    let secondURL = try #require(
      URL(string: "arcane-mobile://oidc-callback?code=second&state=state"))
    let callback = OIDCAuthenticator.makeCallbackStream()
    callback.completionHandler(firstURL, nil)
    callback.completionHandler(secondURL, nil)

    var cancellationCount = 0
    let result = try await OIDCAuthenticator.awaitCallback(
      stream: callback.stream,
      start: { true },
      cancel: { cancellationCount += 1 }
    )

    #expect(result == firstURL)
    #expect(cancellationCount == 0)
  }

  @Test
  func testErrorThenSuccessPreservesFirstError() async throws {
    let callbackURL = try #require(
      URL(string: "arcane-mobile://oidc-callback?code=success&state=state"))
    let callback = OIDCAuthenticator.makeCallbackStream()
    callback.completionHandler(nil, CallbackError.expected)
    callback.completionHandler(callbackURL, nil)

    do {
      _ = try await OIDCAuthenticator.awaitCallback(
        stream: callback.stream,
        start: { true },
        cancel: {}
      )
      Issue.record("Expected the first callback error")
    } catch CallbackError.expected {
      // Expected.
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }

  @Test
  func testSuccessThenErrorPreservesFirstURL() async throws {
    let callbackURL = try #require(
      URL(string: "arcane-mobile://oidc-callback?code=success&state=state"))
    let callback = OIDCAuthenticator.makeCallbackStream()
    callback.completionHandler(callbackURL, nil)
    callback.completionHandler(nil, CallbackError.expected)

    let result = try await OIDCAuthenticator.awaitCallback(
      stream: callback.stream,
      start: { true },
      cancel: {}
    )

    #expect(result == callbackURL)
  }

  @Test
  func testMissingCallbackURLThrowsLocalizedError() async {
    let callback = OIDCAuthenticator.makeCallbackStream()
    callback.completionHandler(nil, nil)

    do {
      _ = try await OIDCAuthenticator.awaitCallback(
        stream: callback.stream,
        start: { true },
        cancel: {}
      )
      Issue.record("Expected a missing callback URL error")
    } catch OIDCAuthenticator.SignInError.invalidCallbackURL {
      #expect(
        OIDCAuthenticator.SignInError.invalidCallbackURL.errorDescription
          == "The identity provider did not return an OIDC callback URL."
      )
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }

  @Test
  func testSignInErrorsHaveUsefulDescriptions() {
    #expect(
      OIDCAuthenticator.SignInError.invalidAuthorizationURL.errorDescription
        == "Arcane returned an invalid OIDC authorization URL."
    )
    #expect(
      OIDCAuthenticator.SignInError.missingCodeOrState.errorDescription
        == "The OIDC callback did not include the required code and state."
    )
    #expect(
      OIDCAuthenticator.SignInError.sessionDidNotStart.errorDescription
        == "The secure sign-in session could not be started."
    )
  }

  @Test
  func testFailedSessionStartThrowsImmediately() async {
    let callback = OIDCAuthenticator.makeCallbackStream()
    var startCount = 0
    var cancellationCount = 0

    do {
      _ = try await OIDCAuthenticator.awaitCallback(
        stream: callback.stream,
        start: {
          startCount += 1
          return false
        },
        cancel: { cancellationCount += 1 }
      )
      Issue.record("Expected the session start to fail")
    } catch OIDCAuthenticator.SignInError.sessionDidNotStart {
      // Expected.
    } catch {
      Issue.record("Unexpected error: \(error)")
    }

    #expect(startCount == 1)
    #expect(cancellationCount == 0)
  }

  @Test
  func testCancellationBeforeStartDoesNotStartSession() async {
    let callback = OIDCAuthenticator.makeCallbackStream()
    var startCount = 0
    var cancellationCount = 0
    let task = Task { @MainActor in
      try await OIDCAuthenticator.awaitCallback(
        stream: callback.stream,
        start: {
          startCount += 1
          return true
        },
        cancel: { cancellationCount += 1 }
      )
    }
    task.cancel()

    do {
      _ = try await task.value
      Issue.record("Expected task cancellation")
    } catch is CancellationError {
      // Expected.
    } catch {
      Issue.record("Unexpected error: \(error)")
    }

    #expect(startCount == 0)
    #expect(cancellationCount == 0)
  }

  @Test
  func testTaskCancellationCancelsStartedSession() async {
    let callback = OIDCAuthenticator.makeCallbackStream()
    let started = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingOldest(1))
    var cancellationCount = 0

    let task = Task { @MainActor in
      try await OIDCAuthenticator.awaitCallback(
        stream: callback.stream,
        start: {
          started.continuation.yield()
          started.continuation.finish()
          return true
        },
        cancel: { cancellationCount += 1 }
      )
    }

    var startedIterator = started.stream.makeAsyncIterator()
    _ = await startedIterator.next()
    task.cancel()

    do {
      _ = try await task.value
      Issue.record("Expected task cancellation")
    } catch is CancellationError {
      // Expected.
    } catch {
      Issue.record("Unexpected error: \(error)")
    }

    #expect(cancellationCount == 1)
  }

  @Test
  func testNormalSuccessProducesOneCallbackURL() async throws {
    let callbackURL = try #require(
      URL(string: "arcane-mobile://oidc-callback?code=success&state=state"))
    let callback = OIDCAuthenticator.makeCallbackStream()
    callback.completionHandler(callbackURL, nil)

    var iterator = callback.stream.makeAsyncIterator()
    let result = try await iterator.next()
    let end = try await iterator.next()
    #expect(result == callbackURL)
    #expect(end == nil)
  }

  @Test
  func testNormalSuccessInvokesBackendCallbackOnce() async throws {
    OIDCMockURLProtocol.reset()
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [OIDCMockURLProtocol.self]
    let client = ArcaneClient(
      configuration: .init(
        baseURL: try #require(URL(string: "https://arcane.example.com")),
        urlSession: URLSession(configuration: configuration)
      )
    )
    let authenticator = OIDCAuthenticator(client: client)
    let callbackURL = try #require(
      URL(string: "arcane-mobile://oidc-callback?code=success&state=state"))

    let result = try await authenticator.completeSignIn(
      callbackURL: callbackURL,
      redirectURI: "arcane-mobile://oidc-callback"
    )

    #expect(result.user.username == "oidc-user")
    #expect(result.tokens.accessToken == "access-token")
    #expect(OIDCMockURLProtocol.callbackRequestCount == 1)
  }
}
