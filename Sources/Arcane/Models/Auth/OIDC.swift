import Foundation

public struct OIDCStatusInfo: Codable, Hashable, Sendable {
  public var envForced: Bool
  public var envConfigured: Bool
  public var mergeAccounts: Bool
  public var providerName: String?
  public var providerLogoUrl: String?

  public init(
    envForced: Bool,
    envConfigured: Bool,
    mergeAccounts: Bool,
    providerName: String? = nil,
    providerLogoUrl: String? = nil
  ) {
    self.envForced = envForced
    self.envConfigured = envConfigured
    self.mergeAccounts = mergeAccounts
    self.providerName = providerName
    self.providerLogoUrl = providerLogoUrl
  }
}

public struct OIDCAuthURLRequest: Codable, Hashable, Sendable {
  public var redirectUri: String
  public var mobileRedirectUri: String?

  public init(redirectUri: String, mobileRedirectUri: String? = nil) {
    self.redirectUri = redirectUri
    self.mobileRedirectUri = mobileRedirectUri
  }
}

public struct OIDCAuthURLResponse: Codable, Hashable, Sendable {
  public var authUrl: String

  public init(authUrl: String) {
    self.authUrl = authUrl
  }
}

public struct OIDCConfigResponse: Codable, Hashable, Sendable {
  public var clientId: String
  public var redirectUri: String
  public var issuerUrl: String
  public var authorizationEndpoint: String
  public var tokenEndpoint: String
  public var userinfoEndpoint: String
  public var deviceAuthorizationEndpoint: String?
  public var scopes: String

  public init(
    clientId: String,
    redirectUri: String,
    issuerUrl: String,
    authorizationEndpoint: String,
    tokenEndpoint: String,
    userinfoEndpoint: String,
    deviceAuthorizationEndpoint: String? = nil,
    scopes: String
  ) {
    self.clientId = clientId
    self.redirectUri = redirectUri
    self.issuerUrl = issuerUrl
    self.authorizationEndpoint = authorizationEndpoint
    self.tokenEndpoint = tokenEndpoint
    self.userinfoEndpoint = userinfoEndpoint
    self.deviceAuthorizationEndpoint = deviceAuthorizationEndpoint
    self.scopes = scopes
  }
}

public struct OIDCCallbackRequest: Codable, Hashable, Sendable {
  public var code: String
  public var state: String
  public var mobileRedirectUri: String?

  public init(code: String, state: String, mobileRedirectUri: String? = nil) {
    self.code = code
    self.state = state
    self.mobileRedirectUri = mobileRedirectUri
  }
}

public struct OIDCCallbackResponse: Codable, Hashable, Sendable {
  public var success: Bool
  public var token: String
  public var refreshToken: String
  public var expiresAt: Date
  public var user: User

  public init(success: Bool, token: String, refreshToken: String, expiresAt: Date, user: User) {
    self.success = success
    self.token = token
    self.refreshToken = refreshToken
    self.expiresAt = expiresAt
    self.user = user
  }
}

public struct OIDCDeviceAuthRequest: Codable, Hashable, Sendable {
  public var redirectUri: String?

  public init(redirectUri: String? = nil) {
    self.redirectUri = redirectUri
  }
}

public struct OIDCDeviceAuthResponse: Codable, Hashable, Sendable {
  public var deviceCode: String
  public var userCode: String
  public var verificationUri: String
  public var verificationUriComplete: String?
  public var expiresIn: Int
  public var interval: Int?

  public init(
    deviceCode: String,
    userCode: String,
    verificationUri: String,
    verificationUriComplete: String? = nil,
    expiresIn: Int,
    interval: Int? = nil
  ) {
    self.deviceCode = deviceCode
    self.userCode = userCode
    self.verificationUri = verificationUri
    self.verificationUriComplete = verificationUriComplete
    self.expiresIn = expiresIn
    self.interval = interval
  }
}

public struct OIDCDeviceTokenRequest: Codable, Hashable, Sendable {
  public var deviceCode: String

  public init(deviceCode: String) {
    self.deviceCode = deviceCode
  }
}

public struct OIDCDeviceTokenResponse: Codable, Hashable, Sendable {
  public var success: Bool
  public var token: String
  public var refreshToken: String
  public var expiresAt: Date
  public var user: User

  public init(success: Bool, token: String, refreshToken: String, expiresAt: Date, user: User) {
    self.success = success
    self.token = token
    self.refreshToken = refreshToken
    self.expiresAt = expiresAt
    self.user = user
  }
}
