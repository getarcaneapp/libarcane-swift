import Foundation

public struct PasskeysService: Sendable {
  private let rest: RESTService
  private let authManager: AuthManager

  init(rest: RESTService, authManager: AuthManager) {
    self.rest = rest
    self.authManager = authManager
  }

  public func beginLogin() async throws -> PasskeyChallenge {
    try await rest.transport.request(
      "auth/passkey/login/begin",
      method: "POST",
      authorized: false
    )
  }

  public func finishLogin(
    ceremonyId: String,
    credential: PasskeyCredential
  ) async throws -> AuthenticationResult {
    let result: AuthenticationResult = try await rest.transport.request(
      "auth/passkey/login/finish",
      method: "POST",
      body: PasskeyFinishRequest(ceremonyId: ceremonyId, credential: credential),
      authorized: false
    )
    try await authManager.save(authenticationResult: result)
    return result
  }

  public func exchangeMobileLogin(
    transactionId: String,
    codeVerifier: String
  ) async throws -> AuthenticationResult {
    let result: AuthenticationResult = try await rest.transport.request(
      "auth/passkey/mobile/exchange",
      method: "POST",
      body: MobilePasskeyExchangeRequest(
        transactionId: transactionId,
        codeVerifier: codeVerifier
      ),
      authorized: false
    )
    try await authManager.save(authenticationResult: result)
    return result
  }

  public func beginMFA(transactionId: String) async throws -> MFAChallenge {
    try await rest.transport.request(
      "auth/mfa/passkey/begin",
      method: "POST",
      body: MFAStartRequest(transactionId: transactionId),
      authorized: false
    )
  }

  public func finishMFA(
    transactionId: String,
    credential: PasskeyCredential
  ) async throws -> AuthenticationResult {
    let result: AuthenticationResult = try await rest.transport.request(
      "auth/mfa/passkey/finish",
      method: "POST",
      body: MFAFinishRequest(transactionId: transactionId, credential: credential),
      authorized: false
    )
    try await authManager.save(authenticationResult: result)
    return result
  }

  public func finishRecovery(
    transactionId: String,
    code: String
  ) async throws -> AuthenticationResult {
    let result: AuthenticationResult = try await rest.transport.request(
      "auth/mfa/recovery",
      method: "POST",
      body: RecoveryCodeRequest(transactionId: transactionId, code: code),
      authorized: false
    )
    try await authManager.save(authenticationResult: result)
    return result
  }

  public func list() async throws -> [PasskeySummary] {
    try await rest.get("auth/me/passkeys")
  }

  public func capabilities() async throws -> PasskeyCapabilities {
    try await rest.get("auth/me/passkeys/capabilities")
  }

  public func beginRegistration(stepUpToken: String? = nil) async throws -> PasskeyChallenge {
    try await rest.post(
      "auth/me/passkeys/register/begin",
      body: EmptyBody?.none,
      options: requestOptions(stepUpToken)
    )
  }

  public func finishRegistration(
    ceremonyId: String,
    credential: PasskeyCredential,
    name: String? = nil,
    stepUpToken: String? = nil
  ) async throws -> PasskeySummary {
    try await rest.post(
      "auth/me/passkeys/register/finish",
      body: PasskeyFinishRequest(
        ceremonyId: ceremonyId,
        credential: credential,
        name: name?.trimmingCharacters(in: .whitespacesAndNewlines)
      ),
      options: requestOptions(stepUpToken)
    )
  }

  public func rename(id: String, name: String, stepUpToken: String) async throws
    -> PasskeySummary
  {
    try await rest.put(
      "auth/me/passkeys/\(try encodedPathSegment(id))",
      body: RenamePasskeyRequest(name: name),
      options: requestOptions(stepUpToken)
    )
  }

  public func delete(id: String, stepUpToken: String) async throws {
    try await rest.deleteVoid(
      "auth/me/passkeys/\(try encodedPathSegment(id))",
      options: requestOptions(stepUpToken)
    )
  }

  public func beginStepUp() async throws -> PasskeyChallenge {
    try await rest.post("auth/me/passkeys/reauth/begin", body: EmptyBody?.none)
  }

  public func finishStepUp(
    transactionId: String,
    credential: PasskeyCredential
  ) async throws -> StepUpGrant {
    try await rest.post(
      "auth/me/passkeys/reauth/finish",
      body: MFAFinishRequest(transactionId: transactionId, credential: credential)
    )
  }

  public func passwordStepUp(password: String) async throws -> StepUpGrant {
    try await rest.post(
      "auth/me/passkeys/reauth/password",
      body: PasswordStepUpRequest(password: password)
    )
  }

  public func mfaStatus() async throws -> MFAStatus {
    try await rest.get("auth/me/mfa")
  }

  public func enableMFA(stepUpToken: String) async throws -> RecoveryCodesResponse {
    try await rest.post(
      "auth/me/mfa/enable",
      body: EmptyBody?.none,
      options: requestOptions(stepUpToken)
    )
  }

  public func disableMFA(stepUpToken: String) async throws {
    try await rest.postVoid(
      "auth/me/mfa/disable",
      body: EmptyBody?.none,
      options: requestOptions(stepUpToken)
    )
  }

  public func regenerateRecoveryCodes(stepUpToken: String) async throws
    -> RecoveryCodesResponse
  {
    try await rest.post(
      "auth/me/mfa/recovery-codes/regenerate",
      body: EmptyBody?.none,
      options: requestOptions(stepUpToken)
    )
  }

  private func requestOptions(_ stepUpToken: String?) -> ArcaneRequestOptions? {
    guard let stepUpToken, !stepUpToken.isEmpty else { return nil }
    return ArcaneRequestOptions(stepUpToken: stepUpToken)
  }

  private func encodedPathSegment(_ value: String) throws -> String {
    var allowed = CharacterSet.urlPathAllowed
    allowed.remove(charactersIn: "/?#")
    guard !value.isEmpty,
      let encoded = value.addingPercentEncoding(withAllowedCharacters: allowed)
    else {
      throw ArcaneError.validation(fields: ["id": ["Passkey identifier is required."]])
    }
    return encoded
  }
}
