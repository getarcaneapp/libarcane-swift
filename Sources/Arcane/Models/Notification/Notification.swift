import Foundation

/// Identifiers for notification providers.
public enum NotificationProvider: String, Codable, Hashable, Sendable, CaseIterable {
  case discord
  case email
  case telegram
  case signal
  case slack
  case ntfy
  case pushover
  case gotify
  case matrix
  case googlechat
  case generic
}

public struct NotificationEvents: Codable, Hashable, Sendable {
  public var imageUpdate: Bool
  public var containerUpdate: Bool
  public var vulnerabilityFound: Bool
  public var pruneReport: Bool
  public var autoHeal: Bool

  public static let defaults = NotificationEvents()
  public static let allEnabled = NotificationEvents(pruneReport: true, autoHeal: true)

  public init(
    imageUpdate: Bool = true,
    containerUpdate: Bool = true,
    vulnerabilityFound: Bool = true,
    pruneReport: Bool = false,
    autoHeal: Bool = false
  ) {
    self.imageUpdate = imageUpdate
    self.containerUpdate = containerUpdate
    self.vulnerabilityFound = vulnerabilityFound
    self.pruneReport = pruneReport
    self.autoHeal = autoHeal
  }

  private enum CodingKeys: String, CodingKey {
    case imageUpdate = "image_update"
    case containerUpdate = "container_update"
    case vulnerabilityFound = "vulnerability_found"
    case pruneReport = "prune_report"
    case autoHeal = "auto_heal"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    imageUpdate = try container.decodeIfPresent(Bool.self, forKey: .imageUpdate) ?? true
    containerUpdate = try container.decodeIfPresent(Bool.self, forKey: .containerUpdate) ?? true
    vulnerabilityFound =
      try container.decodeIfPresent(Bool.self, forKey: .vulnerabilityFound) ?? true
    pruneReport = try container.decodeIfPresent(Bool.self, forKey: .pruneReport) ?? false
    autoHeal = try container.decodeIfPresent(Bool.self, forKey: .autoHeal) ?? false
  }
}

public enum EmailTLSMode: String, Codable, Hashable, Sendable, CaseIterable {
  case none
  case starttls
  case ssl
}

public enum EmailAuthMode: String, Codable, Hashable, Sendable, CaseIterable {
  case none
  case auto
  case plain
  case login
  case crammd5
}

public enum NotificationConfiguration: Hashable, Sendable {
  case discord(DiscordNotificationConfiguration)
  case email(EmailNotificationConfiguration)
  case telegram(TelegramNotificationConfiguration)
  case signal(SignalNotificationConfiguration)
  case slack(SlackNotificationConfiguration)
  case ntfy(NtfyNotificationConfiguration)
  case pushover(PushoverNotificationConfiguration)
  case gotify(GotifyNotificationConfiguration)
  case matrix(MatrixNotificationConfiguration)
  case googlechat(GoogleChatNotificationConfiguration)
  case generic(GenericNotificationConfiguration)

  public var provider: NotificationProvider {
    switch self {
    case .discord: .discord
    case .email: .email
    case .telegram: .telegram
    case .signal: .signal
    case .slack: .slack
    case .ntfy: .ntfy
    case .pushover: .pushover
    case .gotify: .gotify
    case .matrix: .matrix
    case .googlechat: .googlechat
    case .generic: .generic
    }
  }

  fileprivate var encodedValue: any Encodable {
    switch self {
    case .discord(let value): value
    case .email(let value): value
    case .telegram(let value): value
    case .signal(let value): value
    case .slack(let value): value
    case .ntfy(let value): value
    case .pushover(let value): value
    case .gotify(let value): value
    case .matrix(let value): value
    case .googlechat(let value): value
    case .generic(let value): value
    }
  }

  fileprivate var sanitizedForUpdate: Self {
    switch self {
    case .discord(var value):
      value.token = sanitizedNotificationSecret(value.token)
      return .discord(value)
    case .email(var value):
      value.smtpPassword = sanitizedNotificationSecret(value.smtpPassword)
      return .email(value)
    case .telegram(var value):
      value.botToken = sanitizedNotificationSecret(value.botToken)
      return .telegram(value)
    case .signal(var value):
      value.password = sanitizedNotificationSecret(value.password)
      value.token = sanitizedNotificationSecret(value.token)
      return .signal(value)
    case .slack(var value):
      value.token = sanitizedNotificationSecret(value.token)
      return .slack(value)
    case .ntfy(var value):
      value.password = sanitizedNotificationSecret(value.password)
      return .ntfy(value)
    case .pushover(var value):
      value.token = sanitizedNotificationSecret(value.token)
      return .pushover(value)
    case .gotify(var value):
      value.token = sanitizedNotificationSecret(value.token)
      return .gotify(value)
    case .matrix(var value):
      value.password = sanitizedNotificationSecret(value.password)
      return .matrix(value)
    case .googlechat(var value):
      value.webhookUrl = sanitizedNotificationSecret(value.webhookUrl)
      return .googlechat(value)
    case .generic:
      return self
    }
  }
}

public struct NotificationSettings: Codable, Hashable, Sendable, Identifiable {
  public var id: UInt
  public var enabled: Bool
  public var config: NotificationConfiguration
  public var provider: NotificationProvider { config.provider }

  public init(id: UInt, enabled: Bool, config: NotificationConfiguration) {
    self.id = id
    self.enabled = enabled
    self.config = config
  }

  private enum CodingKeys: String, CodingKey { case id, provider, enabled, config }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(UInt.self, forKey: .id)
    enabled = try container.decode(Bool.self, forKey: .enabled)
    let provider = try container.decode(NotificationProvider.self, forKey: .provider)
    config = try provider.decodeConfiguration(container.superDecoder(forKey: .config))
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(provider, forKey: .provider)
    try container.encode(enabled, forKey: .enabled)
    try config.encodedValue.encode(to: container.superEncoder(forKey: .config))
  }
}

public struct UpdateNotificationSettings: Codable, Hashable, Sendable {
  public var enabled: Bool
  public var config: NotificationConfiguration
  public var provider: NotificationProvider { config.provider }

  public init(enabled: Bool, config: NotificationConfiguration) {
    self.enabled = enabled
    self.config = config
  }

  private enum CodingKeys: String, CodingKey { case provider, enabled, config }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    enabled = try container.decode(Bool.self, forKey: .enabled)
    let provider = try container.decode(NotificationProvider.self, forKey: .provider)
    config = try provider.decodeConfiguration(container.superDecoder(forKey: .config))
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(provider, forKey: .provider)
    try container.encode(enabled, forKey: .enabled)
    try config.sanitizedForUpdate.encodedValue.encode(to: container.superEncoder(forKey: .config))
  }
}

public struct NotificationTestResponse: Codable, Hashable, Sendable {
  public var message: String
  public var warning: String?

  public init(message: String, warning: String? = nil) {
    self.message = message
    self.warning = warning
  }
}

private func sanitizedNotificationSecret(_ value: String?) -> String? {
  guard let value else { return nil }
  let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
  guard !trimmed.isEmpty,
    trimmed.lowercased() != "redacted",
    !trimmed.allSatisfy({ $0 == "*" || $0 == "•" })
  else {
    return nil
  }
  return value
}

public struct AppriseSettings: Codable, Hashable, Sendable, Identifiable {
  public var id: UInt
  public var apiUrl: String
  public var enabled: Bool
  public var imageUpdateTag: String
  public var containerUpdateTag: String

  public init(
    id: UInt,
    apiUrl: String,
    enabled: Bool,
    imageUpdateTag: String,
    containerUpdateTag: String
  ) {
    self.id = id
    self.apiUrl = apiUrl
    self.enabled = enabled
    self.imageUpdateTag = imageUpdateTag
    self.containerUpdateTag = containerUpdateTag
  }
}

public struct UpdateAppriseSettings: Codable, Hashable, Sendable {
  public var apiUrl: String
  public var enabled: Bool
  public var imageUpdateTag: String
  public var containerUpdateTag: String

  public init(
    apiUrl: String,
    enabled: Bool,
    imageUpdateTag: String,
    containerUpdateTag: String
  ) {
    self.apiUrl = apiUrl
    self.enabled = enabled
    self.imageUpdateTag = imageUpdateTag
    self.containerUpdateTag = containerUpdateTag
  }
}

public enum NotificationTestType: String, Codable, Hashable, Sendable, CaseIterable {
  case simple
  case imageUpdate = "image-update"
  case batchImageUpdate = "batch-image-update"
  case vulnerabilityFound = "vulnerability-found"
  case pruneReport = "prune-report"
  case autoHeal = "auto-heal"
}

public enum NotificationDispatchKind: String, Codable, Hashable, Sendable {
  case imageUpdate = "image_update"
  case batchImageUpdate = "batch_image_update"
  case containerUpdate = "container_update"
  case vulnerabilityFound = "vulnerability_found"
  case pruneReport = "prune_report"
  case autoHeal = "auto_heal"
}

public struct NotificationDispatchImageUpdate: Codable, Hashable, Sendable {
  public var imageRef: String
  public var updateInfo: JSONValue

  public init(imageRef: String, updateInfo: JSONValue) {
    self.imageRef = imageRef
    self.updateInfo = updateInfo
  }
}

public struct NotificationDispatchBatchImageUpdate: Codable, Hashable, Sendable {
  public var updates: [String: JSONValue]

  public init(updates: [String: JSONValue]) {
    self.updates = updates
  }
}

public struct NotificationDispatchContainerUpdate: Codable, Hashable, Sendable {
  public var containerName: String
  public var imageRef: String
  public var oldDigest: String?
  public var newDigest: String?

  public init(
    containerName: String,
    imageRef: String,
    oldDigest: String? = nil,
    newDigest: String? = nil
  ) {
    self.containerName = containerName
    self.imageRef = imageRef
    self.oldDigest = oldDigest
    self.newDigest = newDigest
  }
}

public struct NotificationDispatchVulnerabilityFound: Codable, Hashable, Sendable {
  public var cveId: String
  public var cveLink: String
  public var severity: String
  public var imageName: String
  public var fixedVersion: String?
  public var pkgName: String?
  public var installedVersion: String?

  public init(
    cveId: String,
    cveLink: String,
    severity: String,
    imageName: String,
    fixedVersion: String? = nil,
    pkgName: String? = nil,
    installedVersion: String? = nil
  ) {
    self.cveId = cveId
    self.cveLink = cveLink
    self.severity = severity
    self.imageName = imageName
    self.fixedVersion = fixedVersion
    self.pkgName = pkgName
    self.installedVersion = installedVersion
  }
}

public struct NotificationDispatchPruneReport: Codable, Hashable, Sendable {
  public var result: JSONValue

  public init(result: JSONValue) {
    self.result = result
  }
}

public struct NotificationDispatchAutoHeal: Codable, Hashable, Sendable {
  public var containerName: String
  public var containerId: String

  public init(containerName: String, containerId: String) {
    self.containerName = containerName
    self.containerId = containerId
  }
}

public struct NotificationDispatchRequest: Codable, Hashable, Sendable {
  public var kind: NotificationDispatchKind
  public var imageUpdate: NotificationDispatchImageUpdate?
  public var batchImageUpdate: NotificationDispatchBatchImageUpdate?
  public var containerUpdate: NotificationDispatchContainerUpdate?
  public var vulnerabilityFound: NotificationDispatchVulnerabilityFound?
  public var pruneReport: NotificationDispatchPruneReport?
  public var autoHeal: NotificationDispatchAutoHeal?

  public init(
    kind: NotificationDispatchKind,
    imageUpdate: NotificationDispatchImageUpdate? = nil,
    batchImageUpdate: NotificationDispatchBatchImageUpdate? = nil,
    containerUpdate: NotificationDispatchContainerUpdate? = nil,
    vulnerabilityFound: NotificationDispatchVulnerabilityFound? = nil,
    pruneReport: NotificationDispatchPruneReport? = nil,
    autoHeal: NotificationDispatchAutoHeal? = nil
  ) {
    self.kind = kind
    self.imageUpdate = imageUpdate
    self.batchImageUpdate = batchImageUpdate
    self.containerUpdate = containerUpdate
    self.vulnerabilityFound = vulnerabilityFound
    self.pruneReport = pruneReport
    self.autoHeal = autoHeal
  }
}

extension NotificationProvider {
  fileprivate var decodeConfiguration: (any Decoder) throws -> NotificationConfiguration {
    switch self {
    case .discord: { .discord(try DiscordNotificationConfiguration(from: $0)) }
    case .email: { .email(try EmailNotificationConfiguration(from: $0)) }
    case .telegram: { .telegram(try TelegramNotificationConfiguration(from: $0)) }
    case .signal: { .signal(try SignalNotificationConfiguration(from: $0)) }
    case .slack: { .slack(try SlackNotificationConfiguration(from: $0)) }
    case .ntfy: { .ntfy(try NtfyNotificationConfiguration(from: $0)) }
    case .pushover: { .pushover(try PushoverNotificationConfiguration(from: $0)) }
    case .gotify: { .gotify(try GotifyNotificationConfiguration(from: $0)) }
    case .matrix: { .matrix(try MatrixNotificationConfiguration(from: $0)) }
    case .googlechat: { .googlechat(try GoogleChatNotificationConfiguration(from: $0)) }
    case .generic: { .generic(try GenericNotificationConfiguration(from: $0)) }
    }
  }
}
