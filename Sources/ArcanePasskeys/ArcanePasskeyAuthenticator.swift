import Arcane
import AuthenticationServices
import CryptoKit
import Foundation
import Security

@MainActor
public final class ArcanePasskeyAuthenticator: NSObject,
  ASWebAuthenticationPresentationContextProviding
{
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

  private enum Operation: String, Encodable {
    case authenticate
    case register
  }

  private struct BridgeRequest: Encodable {
    let version: Int
    let state: String
    let operation: Operation
    let options: [String: JSONValue]
    let mobileLogin: MobileLoginRequest?
  }

  private struct MobileLoginRequest: Encodable {
    let ceremonyId: String
    let codeChallenge: String
  }

  private static let manifestPath = "/arcane-mobile-passkey.json"
  private static let bridgePath = "/mobile/passkey"
  private static let callbackScheme = "arcane-mobile"
  private static let callbackHost = "passkey-callback"
  private static let localMaximumRequestBytes = 65_536
  private static let maximumManifestBytes = 4_096
  private static let maximumCallbackResponseBytes = 65_536

  private let client: ArcaneClient
  private weak var presentationAnchor: ASPresentationAnchor?
  private var activeSession: ASWebAuthenticationSession?

  public init(client: ArcaneClient) {
    self.client = client
  }

  public func isBridgeAvailable() async -> Bool {
    do {
      _ = try await loadBridgeManifest()
      return true
    } catch {
      return false
    }
  }

  @discardableResult
  public func authenticateLogin(presenting anchor: ASPresentationAnchor) async throws
    -> AuthenticationResult
  {
    let challenge = try await client.passkeys.beginLogin()
    let codeVerifier = try Self.makeState()
    let transactionId = try await performMobileLoginCeremony(
      challenge: challenge,
      codeVerifier: codeVerifier,
      presenting: anchor
    )
    return try await client.passkeys.exchangeMobileLogin(
      transactionId: transactionId,
      codeVerifier: codeVerifier
    )
  }

  @discardableResult
  public func login(presenting anchor: ASPresentationAnchor) async throws -> LoginResponse {
    let result = try await authenticateLogin(presenting: anchor)
    return try authenticatedResponse(from: result)
  }

  @discardableResult
  public func completeMFA(
    challenge: MFAChallenge,
    presenting anchor: ASPresentationAnchor
  ) async throws -> LoginResponse {
    let credential = try await performCeremony(
      operation: .authenticate,
      options: challenge.options,
      presenting: anchor
    )
    let result = try await client.passkeys.finishMFA(
      transactionId: challenge.transactionId,
      credential: credential
    )
    return try authenticatedResponse(from: result)
  }

  @discardableResult
  public func completeMFA(
    transactionId: String,
    presenting anchor: ASPresentationAnchor
  ) async throws -> LoginResponse {
    let challenge = try await client.passkeys.beginMFA(transactionId: transactionId)
    return try await completeMFA(challenge: challenge, presenting: anchor)
  }

  @discardableResult
  public func register(
    name: String? = nil,
    stepUpToken: String? = nil,
    presenting anchor: ASPresentationAnchor
  ) async throws -> PasskeySummary {
    let challenge = try await client.passkeys.beginRegistration(stepUpToken: stepUpToken)
    let credential = try await performCeremony(
      operation: .register,
      options: challenge.options,
      presenting: anchor
    )
    return try await client.passkeys.finishRegistration(
      ceremonyId: challenge.ceremonyId,
      credential: credential,
      name: name,
      stepUpToken: stepUpToken
    )
  }

  @discardableResult
  public func stepUp(presenting anchor: ASPresentationAnchor) async throws -> StepUpGrant {
    let challenge = try await client.passkeys.beginStepUp()
    guard let transactionId = challenge.transactionId else {
      throw CeremonyError.invalidCredential
    }
    let credential = try await performCeremony(
      operation: .authenticate,
      options: challenge.options,
      presenting: anchor
    )
    return try await client.passkeys.finishStepUp(
      transactionId: transactionId,
      credential: credential
    )
  }

  public func cancel() {
    activeSession?.cancel()
    activeSession = nil
    presentationAnchor = nil
  }

  public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    presentationAnchor ?? ASPresentationAnchor()
  }

  private func performCeremony(
    operation: Operation,
    options: [String: JSONValue],
    presenting anchor: ASPresentationAnchor
  ) async throws -> PasskeyCredential {
    let state = try Self.makeState()
    let request = BridgeRequest(
      version: 2,
      state: state,
      operation: operation,
      options: options,
      mobileLogin: nil
    )
    let callbackURL = try await openBridge(request: request, presenting: anchor)
    return try Self.parseCallback(callbackURL, expectedState: state)
  }

  private func performMobileLoginCeremony(
    challenge: PasskeyChallenge,
    codeVerifier: String,
    presenting anchor: ASPresentationAnchor
  ) async throws -> String {
    let state = try Self.makeState()
    let request = BridgeRequest(
      version: 2,
      state: state,
      operation: .authenticate,
      options: challenge.options,
      mobileLogin: MobileLoginRequest(
        ceremonyId: challenge.ceremonyId,
        codeChallenge: Self.codeChallenge(for: codeVerifier)
      )
    )
    let callbackURL = try await openBridge(request: request, presenting: anchor)
    return try Self.parseMobileLoginCallback(callbackURL, expectedState: state)
  }

  private func openBridge(
    request: BridgeRequest,
    presenting anchor: ASPresentationAnchor
  ) async throws -> URL {
    let manifest = try await loadBridgeManifest()
    let data = try ArcaneJSON.makeEncoder().encode(request)
    guard data.count <= min(manifest.maximumRequestBytes, Self.localMaximumRequestBytes) else {
      throw CeremonyError.requestTooLarge
    }

    guard let origin = Self.serverOrigin(from: client.configuration.baseURL),
      var components = URLComponents(
        url: origin.appendingPathComponent("mobile/passkey"), resolvingAgainstBaseURL: false)
    else {
      throw CeremonyError.unsupportedOrigin
    }
    components.percentEncodedFragment = "request=\(data.base64URLEncodedString())"
    guard let authorizationURL = components.url else {
      throw CeremonyError.invalidManifest
    }
    return try await openBridge(authorizationURL: authorizationURL, presenting: anchor)
  }

  private func loadBridgeManifest() async throws -> BridgeManifest {
    guard let origin = Self.serverOrigin(from: client.configuration.baseURL) else {
      throw CeremonyError.unsupportedOrigin
    }

    let url = origin.appendingPathComponent(
      Self.manifestPath.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    let (data, response) = try await client.configuration.urlSession.data(from: url)
    guard let response = response as? HTTPURLResponse,
      (200..<300).contains(response.statusCode),
      data.count <= Self.maximumManifestBytes
    else {
      throw CeremonyError.bridgeUnavailable
    }

    let manifest: BridgeManifest
    do {
      manifest = try JSONDecoder().decode(BridgeManifest.self, from: data)
    } catch {
      throw CeremonyError.invalidManifest
    }

    guard manifest.version == 2,
      manifest.path == Self.bridgePath,
      manifest.requestFragmentParameter == "request",
      (1...Self.localMaximumRequestBytes).contains(manifest.maximumRequestBytes)
    else {
      throw CeremonyError.invalidManifest
    }
    return manifest
  }

  private func openBridge(
    authorizationURL: URL,
    presenting anchor: ASPresentationAnchor
  ) async throws -> URL {
    presentationAnchor = anchor
    let callback = Self.makeCallbackStream()
    let session = ASWebAuthenticationSession(
      url: authorizationURL,
      callback: .customScheme(Self.callbackScheme),
      completionHandler: callback.completionHandler
    )
    session.presentationContextProvider = self
    session.prefersEphemeralWebBrowserSession = true
    activeSession = session

    defer {
      activeSession = nil
      presentationAnchor = nil
    }

    return try await Self.awaitCallback(
      stream: callback.stream,
      start: { session.start() },
      cancel: { session.cancel() }
    )
  }

  private func authenticatedResponse(from result: AuthenticationResult) throws -> LoginResponse {
    switch result {
    case .authenticated(let response):
      response
    case .mfaRequired(let challenge):
      throw MFARequiredError(challenge: challenge)
    }
  }

  nonisolated static func makeCallbackStream() -> (
    stream: AsyncThrowingStream<URL, Error>,
    completionHandler: ASWebAuthenticationSession.CompletionHandler
  ) {
    let callback = AsyncThrowingStream<URL, Error>.makeStream(
      bufferingPolicy: .bufferingOldest(1)
    )
    let completionHandler: ASWebAuthenticationSession.CompletionHandler = { callbackURL, error in
      if let error {
        callback.continuation.finish(throwing: error)
        return
      }
      guard let callbackURL else {
        callback.continuation.finish(throwing: CeremonyError.invalidCallback)
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
      throw CeremonyError.sessionDidNotStart
    }

    do {
      var iterator = stream.makeAsyncIterator()
      guard let callbackURL = try await iterator.next() else {
        if Task.isCancelled { throw CancellationError() }
        throw CeremonyError.invalidCallback
      }
      try Task.checkCancellation()
      return callbackURL
    } catch {
      guard Task.isCancelled else { throw error }
      cancel()
      throw CancellationError()
    }
  }

  static func parseCallback(_ url: URL, expectedState: String) throws -> PasskeyCredential {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      components.scheme == callbackScheme,
      components.host == callbackHost,
      components.path.isEmpty,
      components.user == nil,
      components.password == nil,
      components.port == nil,
      components.fragment == nil,
      let queryItems = components.queryItems
    else {
      throw CeremonyError.invalidCallback
    }

    let grouped = Dictionary(grouping: queryItems, by: \.name)
    guard grouped.values.allSatisfy({ $0.count == 1 }) else {
      throw CeremonyError.duplicateCallbackItem
    }
    guard grouped["state"]?.first?.value == expectedState else {
      throw CeremonyError.stateMismatch
    }

    if let errorCode = grouped["error"]?.first?.value {
      guard Set(grouped.keys) == ["state", "error"],
        ["invalid_request", "oversized", "unsupported", "cancelled", "failed"].contains(errorCode)
      else {
        throw CeremonyError.invalidCallback
      }
      if errorCode == "cancelled" {
        throw CeremonyError.cancelled
      }
      throw CeremonyError.bridgeFailure(errorCode)
    }

    guard Set(grouped.keys) == ["state", "response"],
      let encodedResponse = grouped["response"]?.first?.value,
      encodedResponse.utf8.count <= ((maximumCallbackResponseBytes * 4) / 3) + 4,
      let data = Data(base64URLEncoded: encodedResponse),
      data.count <= maximumCallbackResponseBytes
    else {
      throw CeremonyError.invalidCallback
    }

    do {
      return try JSONDecoder().decode(PasskeyCredential.self, from: data)
    } catch {
      throw CeremonyError.invalidCredential
    }
  }

  static func parseMobileLoginCallback(_ url: URL, expectedState: String) throws -> String {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      components.scheme == callbackScheme,
      components.host == callbackHost,
      components.path.isEmpty,
      components.user == nil,
      components.password == nil,
      components.port == nil,
      components.fragment == nil,
      let queryItems = components.queryItems
    else {
      throw CeremonyError.invalidCallback
    }

    let grouped = Dictionary(grouping: queryItems, by: \.name)
    guard grouped.values.allSatisfy({ $0.count == 1 }) else {
      throw CeremonyError.duplicateCallbackItem
    }
    guard grouped["state"]?.first?.value == expectedState else {
      throw CeremonyError.stateMismatch
    }
    if let errorCode = grouped["error"]?.first?.value {
      guard Set(grouped.keys) == ["state", "error"],
        ["invalid_request", "oversized", "unsupported", "cancelled", "failed"].contains(
          errorCode)
      else {
        throw CeremonyError.invalidCallback
      }
      if errorCode == "cancelled" {
        throw CeremonyError.cancelled
      }
      throw CeremonyError.bridgeFailure(errorCode)
    }

    guard Set(grouped.keys) == ["state", "transaction"],
      let transactionId = grouped["transaction"]?.first?.value,
      !transactionId.isEmpty,
      transactionId.utf8.count <= 128
    else {
      throw CeremonyError.invalidCallback
    }
    return transactionId
  }

  static func serverOrigin(from baseURL: URL) -> URL? {
    guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false),
      let scheme = components.scheme?.lowercased(),
      let host = components.host?.lowercased(),
      scheme == "https" || (scheme == "http" && isLoopbackHost(host))
    else {
      return nil
    }
    components.path = "/"
    components.query = nil
    components.fragment = nil
    components.user = nil
    components.password = nil
    return components.url
  }

  private static func isLoopbackHost(_ host: String) -> Bool {
    host == "localhost" || host.hasSuffix(".localhost") || host == "::1" || host.hasPrefix("127.")
  }

  private static func makeState() throws -> String {
    var bytes = [UInt8](repeating: 0, count: 32)
    let status = bytes.withUnsafeMutableBytes { buffer in
      SecRandomCopyBytes(kSecRandomDefault, buffer.count, buffer.baseAddress!)
    }
    guard status == errSecSuccess else {
      throw CeremonyError.randomStateGenerationFailed
    }
    return Data(bytes).base64URLEncodedString()
  }

  private static func codeChallenge(for verifier: String) -> String {
    Data(SHA256.hash(data: Data(verifier.utf8))).base64URLEncodedString()
  }
}

extension Data {
  fileprivate init?(base64URLEncoded value: String) {
    guard value.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") })
    else {
      return nil
    }
    let padding = String(repeating: "=", count: (4 - value.count % 4) % 4)
    self.init(
      base64Encoded: value.replacingOccurrences(of: "-", with: "+").replacingOccurrences(
        of: "_", with: "/") + padding)
  }

  fileprivate func base64URLEncodedString() -> String {
    base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}
