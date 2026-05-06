import Arcane
import AuthenticationServices
import Foundation

@MainActor
public final class OIDCAuthenticator: NSObject, ASWebAuthenticationPresentationContextProviding {
    private let client: ArcaneClient
    private weak var presentationAnchor: ASPresentationAnchor?

    public init(client: ArcaneClient) {
        self.client = client
    }

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

    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        presentationAnchor ?? ASPresentationAnchor()
    }
}
