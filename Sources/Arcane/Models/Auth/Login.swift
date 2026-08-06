import Foundation

public struct LoginRequest: Codable, Hashable, Sendable {
  public var username: String
  public var password: String

  public init(username: String, password: String) {
    self.username = username
    self.password = password
  }
}

public struct LoginResponse: Codable, Hashable, Sendable {
  public var token: String
  public var refreshToken: String
  public var expiresAt: Date
  public var user: User

  public init(token: String, refreshToken: String, expiresAt: Date, user: User) {
    self.token = token
    self.refreshToken = refreshToken
    self.expiresAt = expiresAt
    self.user = user
  }
}

public struct MFAChallenge: Codable, Hashable, Sendable {
  public var transactionId: String
  public var method: String
  public var options: [String: JSONValue]
  public var expiresAt: Date

  private enum CodingKeys: String, CodingKey {
    case transactionId
    case method
    case options
    case expiresAt
  }

  public init(
    transactionId: String,
    method: String = "passkey",
    options: [String: JSONValue] = [:],
    expiresAt: Date
  ) {
    self.transactionId = transactionId
    self.method = method
    self.options = options
    self.expiresAt = expiresAt
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    transactionId = try container.decode(String.self, forKey: .transactionId)
    method = try container.decodeIfPresent(String.self, forKey: .method) ?? "passkey"
    options = try container.decodeIfPresent([String: JSONValue].self, forKey: .options) ?? [:]
    expiresAt = try container.decode(Date.self, forKey: .expiresAt)
  }
}

public enum AuthenticationResult: Codable, Hashable, Sendable {
  case authenticated(LoginResponse)
  case mfaRequired(MFAChallenge)

  private enum CodingKeys: String, CodingKey {
    case success
    case status
    case token
    case refreshToken
    case expiresAt
    case user
    case mfa
    case challenge
  }

  private enum Status: String, Codable {
    case authenticated
    case mfaRequired = "mfa_required"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let status = try container.decodeIfPresent(Status.self, forKey: .status)

    if status == .mfaRequired {
      if let challenge = try container.decodeIfPresent(MFAChallenge.self, forKey: .mfa)
        ?? container.decodeIfPresent(MFAChallenge.self, forKey: .challenge)
      {
        self = .mfaRequired(challenge)
      } else {
        self = .mfaRequired(try MFAChallenge(from: decoder))
      }
      return
    }

    self = .authenticated(
      LoginResponse(
        token: try container.decode(String.self, forKey: .token),
        refreshToken: try container.decode(String.self, forKey: .refreshToken),
        expiresAt: try container.decode(Date.self, forKey: .expiresAt),
        user: try container.decode(User.self, forKey: .user)
      ))
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(true, forKey: .success)
    switch self {
    case .authenticated(let response):
      try container.encode(Status.authenticated, forKey: .status)
      try container.encode(response.token, forKey: .token)
      try container.encode(response.refreshToken, forKey: .refreshToken)
      try container.encode(response.expiresAt, forKey: .expiresAt)
      try container.encode(response.user, forKey: .user)
    case .mfaRequired(let challenge):
      try container.encode(Status.mfaRequired, forKey: .status)
      try container.encode(challenge, forKey: .mfa)
    }
  }
}

public struct MFARequiredError: LocalizedError, Hashable, Sendable {
  public let challenge: MFAChallenge

  public init(challenge: MFAChallenge) {
    self.challenge = challenge
  }

  public var errorDescription: String? {
    "Multi-factor authentication is required."
  }
}

public struct RefreshRequest: Codable, Hashable, Sendable {
  public var refreshToken: String

  public init(refreshToken: String) {
    self.refreshToken = refreshToken
  }
}

public struct TokenRefreshResponse: Codable, Hashable, Sendable {
  public var token: String
  public var refreshToken: String
  public var expiresAt: Date

  public init(token: String, refreshToken: String, expiresAt: Date) {
    self.token = token
    self.refreshToken = refreshToken
    self.expiresAt = expiresAt
  }
}

public struct PasswordChange: Codable, Hashable, Sendable {
  public var currentPassword: String?
  public var newPassword: String

  public init(currentPassword: String? = nil, newPassword: String) {
    self.currentPassword = currentPassword
    self.newPassword = newPassword
  }
}

public struct AutoLoginConfig: Codable, Hashable, Sendable {
  public var enabled: Bool
  public var username: String

  public init(enabled: Bool, username: String) {
    self.enabled = enabled
    self.username = username
  }
}
