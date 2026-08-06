import Foundation

public typealias PasskeyCredential = [String: JSONValue]

public struct PasskeyChallenge: Codable, Hashable, Sendable {
  public var ceremonyId: String
  public var transactionId: String?
  public var options: [String: JSONValue]
  public var expiresAt: Date

  public init(
    ceremonyId: String,
    transactionId: String? = nil,
    options: [String: JSONValue],
    expiresAt: Date
  ) {
    self.ceremonyId = ceremonyId
    self.transactionId = transactionId
    self.options = options
    self.expiresAt = expiresAt
  }
}

public struct PasskeySummary: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var name: String
  public var rpId: String
  public var aaguid: String?
  public var transports: [String]?
  public var backupEligible: Bool
  public var backupState: Bool
  public var cloneWarning: Bool
  public var authenticatorAttachment: String?
  public var createdAt: Date
  public var updatedAt: Date?
  public var lastUsedAt: Date?

  public init(
    id: String,
    name: String,
    rpId: String,
    aaguid: String? = nil,
    transports: [String]? = nil,
    backupEligible: Bool,
    backupState: Bool,
    cloneWarning: Bool,
    authenticatorAttachment: String? = nil,
    createdAt: Date,
    updatedAt: Date? = nil,
    lastUsedAt: Date? = nil
  ) {
    self.id = id
    self.name = name
    self.rpId = rpId
    self.aaguid = aaguid
    self.transports = transports
    self.backupEligible = backupEligible
    self.backupState = backupState
    self.cloneWarning = cloneWarning
    self.authenticatorAttachment = authenticatorAttachment
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.lastUsedAt = lastUsedAt
  }
}

public struct PasskeyCapabilities: Codable, Hashable, Sendable {
  public var passkeyMfaEnabled: Bool
  public var passkeyCount: Int
  public var hasLocalPassword: Bool
  public var hasOidcFallback: Bool
  public var canEnrollWithActiveSession: Bool
  public var canDeleteLastPasskey: Bool
  public var requiresStepUp: Bool

  public init(
    passkeyMfaEnabled: Bool,
    passkeyCount: Int,
    hasLocalPassword: Bool,
    hasOidcFallback: Bool,
    canEnrollWithActiveSession: Bool,
    canDeleteLastPasskey: Bool,
    requiresStepUp: Bool
  ) {
    self.passkeyMfaEnabled = passkeyMfaEnabled
    self.passkeyCount = passkeyCount
    self.hasLocalPassword = hasLocalPassword
    self.hasOidcFallback = hasOidcFallback
    self.canEnrollWithActiveSession = canEnrollWithActiveSession
    self.canDeleteLastPasskey = canDeleteLastPasskey
    self.requiresStepUp = requiresStepUp
  }
}

public struct MFAStatus: Codable, Hashable, Sendable {
  public var enabled: Bool
  public var passkeyCount: Int
  public var recoveryCodesRemaining: Int

  public init(enabled: Bool, passkeyCount: Int, recoveryCodesRemaining: Int) {
    self.enabled = enabled
    self.passkeyCount = passkeyCount
    self.recoveryCodesRemaining = recoveryCodesRemaining
  }
}

public struct RecoveryCodesResponse: Codable, Hashable, Sendable {
  public var codes: [String]

  public init(codes: [String]) {
    self.codes = codes
  }
}

public struct StepUpGrant: Codable, Hashable, Sendable {
  public var token: String
  public var expiresAt: Date

  public init(token: String, expiresAt: Date) {
    self.token = token
    self.expiresAt = expiresAt
  }
}

struct PasskeyFinishRequest: Codable, Hashable, Sendable {
  var ceremonyId: String
  var credential: PasskeyCredential
  var name: String?

  init(ceremonyId: String, credential: PasskeyCredential, name: String? = nil) {
    self.ceremonyId = ceremonyId
    self.credential = credential
    self.name = name
  }
}

struct MFAStartRequest: Codable, Hashable, Sendable {
  var transactionId: String
}

struct MFAFinishRequest: Codable, Hashable, Sendable {
  var transactionId: String
  var credential: PasskeyCredential
}

struct RecoveryCodeRequest: Codable, Hashable, Sendable {
  var transactionId: String
  var code: String
}

struct RenamePasskeyRequest: Codable, Hashable, Sendable {
  var name: String
}

struct PasswordStepUpRequest: Codable, Hashable, Sendable {
  var password: String
}
