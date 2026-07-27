import Arcane
import AuthenticationServices
import Foundation

@MainActor
public final class OIDCAuthenticator: NSObject, ASWebAuthenticationPresentationContextProviding {
  public struct SignInResult: Sendable {
    public let user: User
    public let tokens: TokenPair
  }

  public nonisolated enum SignInError: LocalizedError, Sendable {
    case invalidAuthorizationURL
    case invalidCallbackURL
    case missingCodeOrState
    case sessionDidNotStart

    public var errorDescription: String? {
      switch self {
      case .invalidAuthorizationURL:
        "Arcane returned an invalid OIDC authorization URL."
      case .invalidCallbackURL:
        "The identity provider did not return an OIDC callback URL."
      case .missingCodeOrState:
        "The OIDC callback did not include the required code and state."
      case .sessionDidNotStart:
        "The secure sign-in session could not be started."
      }
    }
  }

  private let client: ArcaneClient
  private weak var presentationAnchor: ASPresentationAnchor?

  public init(client: ArcaneClient) {
    self.client = client
  }

  // Low-level entry point: caller already has an authorization URL and
  // wants to drive the OAuth flow directly. Returns the callback URL.
  public func signIn(
    callbackURLScheme: String, authorizationURL: URL, presenting anchor: ASPresentationAnchor
  ) async throws -> URL {
    self.presentationAnchor = anchor
    let callback = Self.makeCallbackStream()
    let session = ASWebAuthenticationSession(
      url: authorizationURL,
      callback: .customScheme(callbackURLScheme),
      completionHandler: callback.completionHandler
    )
    session.presentationContextProvider = self
    session.prefersEphemeralWebBrowserSession = true

    return try await Self.awaitCallback(
      stream: callback.stream,
      start: { session.start() },
      cancel: { session.cancel() }
    )
  }

  // High-level orchestration: ask the backend for an auth URL, drive the
  // ASWebAuthenticationSession, then complete the callback with the backend.
  // Tokens are persisted via the client's AuthManager on success.
  @discardableResult
  public func signIn(
    callbackURLScheme: String,
    redirectURI: String,
    presenting anchor: ASPresentationAnchor
  ) async throws -> SignInResult {
    let authURLResponse = try await client.auth.oidcAuthURL(mobileRedirectURI: redirectURI)
    guard let authorizationURL = URL(string: authURLResponse.authUrl) else {
      throw SignInError.invalidAuthorizationURL
    }

    let callbackURL = try await signIn(
      callbackURLScheme: callbackURLScheme,
      authorizationURL: authorizationURL,
      presenting: anchor
    )
    return try await completeSignIn(callbackURL: callbackURL, redirectURI: redirectURI)
  }

  func completeSignIn(callbackURL: URL, redirectURI: String) async throws -> SignInResult {
    let (code, state) = try parseCallback(callbackURL)
    let response = try await client.auth.oidcCallback(
      code: code, state: state, mobileRedirectURI: redirectURI)

    let tokens = TokenPair(
      accessToken: response.token,
      refreshToken: response.refreshToken,
      expiresAt: response.expiresAt
    )
    return SignInResult(user: response.user, tokens: tokens)
  }

  public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    presentationAnchor ?? ASPresentationAnchor()
  }

  nonisolated static func makeCallbackStream() -> (
    stream: AsyncThrowingStream<URL, Error>,
    completionHandler: ASWebAuthenticationSession.CompletionHandler
  ) {
    let callback = AsyncThrowingStream<URL, Error>.makeStream(
      bufferingPolicy: .bufferingOldest(1)
    )
    let completionHandler: ASWebAuthenticationSession.CompletionHandler = {
      callbackURL, error in
      if let error {
        callback.continuation.finish(throwing: error)
        return
      }
      guard let callbackURL else {
        callback.continuation.finish(throwing: SignInError.invalidCallbackURL)
        return
      }
      callback.continuation.yield(callbackURL)
      callback.continuation.finish()
    }
    return (callback.stream, completionHandler)
  }

  static func awaitCallback(
    stream: AsyncThrowingStream<URL, Error>,
    start: @MainActor () -> Bool,
    cancel: @MainActor () -> Void
  ) async throws -> URL {
    try Task.checkCancellation()
    guard start() else {
      try Task.checkCancellation()
      throw SignInError.sessionDidNotStart
    }

    do {
      try Task.checkCancellation()
      var iterator = stream.makeAsyncIterator()
      guard let callbackURL = try await iterator.next() else {
        if Task.isCancelled {
          throw CancellationError()
        }
        throw SignInError.invalidCallbackURL
      }
      try Task.checkCancellation()
      return callbackURL
    } catch {
      guard Task.isCancelled else { throw error }
      cancel()
      throw CancellationError()
    }
  }

  private func parseCallback(_ url: URL) throws -> (code: String, state: String) {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      let items = components.queryItems,
      let code = items.first(where: { $0.name == "code" })?.value,
      let state = items.first(where: { $0.name == "state" })?.value
    else {
      throw SignInError.missingCodeOrState
    }
    return (code, state)
  }
}
