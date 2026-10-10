import Arcane
import Foundation

extension OIDCAuthenticator {
  public struct SignInResult: Sendable {
    public let user: User
    public let tokens: TokenPair
  }

  nonisolated public enum SignInError: LocalizedError, Sendable {
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

}
