import Foundation

extension ArcanePasskeyAuthenticator {
  nonisolated public enum CeremonyError: LocalizedError, Equatable, Sendable {
    case unsupportedOrigin
    case bridgeUnavailable
    case invalidManifest
    case requestTooLarge
    case invalidCallback
    case stateMismatch
    case duplicateCallbackItem
    case cancelled
    case bridgeFailure(String)
    case invalidCredential
    case sessionDidNotStart
    case randomStateGenerationFailed

    public var errorDescription: String? {
      switch self {
      case .unsupportedOrigin:
        "Passkeys require HTTPS or a loopback HTTP Arcane server."
      case .bridgeUnavailable:
        "This Arcane server does not provide the mobile passkey bridge."
      case .invalidManifest:
        "The Arcane mobile passkey bridge manifest is invalid."
      case .requestTooLarge:
        "The passkey request is too large."
      case .invalidCallback:
        "The passkey bridge returned an invalid callback."
      case .stateMismatch:
        "The passkey bridge callback did not match this request."
      case .duplicateCallbackItem:
        "The passkey bridge callback contains duplicate values."
      case .cancelled:
        "The passkey request was cancelled."
      case .bridgeFailure(let code):
        "The passkey bridge failed with \(code)."
      case .invalidCredential:
        "The passkey bridge returned an invalid credential."
      case .sessionDidNotStart:
        "The secure passkey session could not be started."
      case .randomStateGenerationFailed:
        "A secure passkey request state could not be created."
      }
    }
  }

  public struct BridgeManifest: Codable, Hashable, Sendable {
    public let version: Int
    public let path: String
    public let requestFragmentParameter: String
    public let maximumRequestBytes: Int

    public init(
      version: Int,
      path: String,
      requestFragmentParameter: String,
      maximumRequestBytes: Int
    ) {
      self.version = version
      self.path = path
      self.requestFragmentParameter = requestFragmentParameter
      self.maximumRequestBytes = maximumRequestBytes
    }
  }

}
