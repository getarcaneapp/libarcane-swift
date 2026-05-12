import Arcane
import AuthenticationServices
import Foundation

@MainActor
public final class OIDCAuthenticator: NSObject, ASWebAuthenticationPresentationContextProviding {
    public struct SignInResult: Sendable {
        public let user: User
        public let tokens: TokenPair
    }

    public enum SignInError: Error, Sendable {
        case invalidAuthorizationURL
        case invalidCallbackURL
        case missingCodeOrState
    }

    private let client: ArcaneClient
    private weak var presentationAnchor: ASPresentationAnchor?

    public init(client: ArcaneClient) {
        self.client = client
    }

    // Low-level entry point: caller already has an authorization URL and
    // wants to drive the OAuth flow directly. Returns the callback URL.
    public func signIn(callbackURLScheme: String, authorizationURL: URL, presenting anchor: ASPresentationAnchor) async throws -> URL {
        self.presentationAnchor = anchor
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: authorizationURL, callbackURLScheme: callbackURLScheme) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let callbackURL else {
                    continuation.resume(throwing: ArcaneError.unauthorized)
                    return
                }
                continuation.resume(returning: callbackURL)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            session.start()
        }
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

        let (code, state) = try parseCallback(callbackURL)
        let response = try await client.auth.oidcCallback(code: code, state: state, mobileRedirectURI: redirectURI)

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

    private func parseCallback(_ url: URL) throws -> (code: String, state: String) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems,
              let code = items.first(where: { $0.name == "code" })?.value,
              let state = items.first(where: { $0.name == "state" })?.value else {
            throw SignInError.missingCodeOrState
        }
        return (code, state)
    }
}
