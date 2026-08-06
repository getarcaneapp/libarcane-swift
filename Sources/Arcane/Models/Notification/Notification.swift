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

public struct DiscordNotificationConfiguration: Codable, Hashable, Sendable {
  public var webhookId: String
  public var token: String?
  public var username: String?
  public var avatarUrl: String?
  public var events: NotificationEvents?

  public init(
    webhookId: String, token: String? = nil, username: String? = nil, avatarUrl: String? = nil,
    events: NotificationEvents? = .defaults
  ) {
    self.webhookId = webhookId
    self.token = token
    self.username = username
    self.avatarUrl = avatarUrl
    self.events = events
  }
}

public struct EmailNotificationConfiguration: Codable, Hashable, Sendable {
  public var smtpHost: String
  public var smtpPort: Int
  public var smtpUsername: String
  public var smtpPassword: String?
  public var fromAddress: String
  public var toAddresses: [String]
  public var tlsMode: EmailTLSMode
  public var authMode: EmailAuthMode?
  public var events: NotificationEvents?

  public init(
    smtpHost: String, smtpPort: Int, smtpUsername: String, smtpPassword: String? = nil,
    fromAddress: String, toAddresses: [String], tlsMode: EmailTLSMode,
    authMode: EmailAuthMode? = .auto, events: NotificationEvents? = .defaults
  ) {
    self.smtpHost = smtpHost
    self.smtpPort = smtpPort
    self.smtpUsername = smtpUsername
    self.smtpPassword = smtpPassword
    self.fromAddress = fromAddress
    self.toAddresses = toAddresses
    self.tlsMode = tlsMode
    self.authMode = authMode
    self.events = events
  }
}

public struct TelegramNotificationConfiguration: Codable, Hashable, Sendable {
  public var botToken: String?
  public var chatIds: [String]
  public var preview: Bool
  public var notification: Bool
  public var parseMode: String?
  public var title: String?
  public var events: NotificationEvents?

  public init(
    botToken: String? = nil, chatIds: [String], preview: Bool = true, notification: Bool = true,
    parseMode: String? = nil, title: String? = nil, events: NotificationEvents? = .defaults
  ) {
    self.botToken = botToken
    self.chatIds = chatIds
    self.preview = preview
    self.notification = notification
    self.parseMode = parseMode
    self.title = title
    self.events = events
  }
}

public struct SignalNotificationConfiguration: Codable, Hashable, Sendable {
  public var host: String
  public var port: Int
  public var user: String?
  public var password: String?
  public var token: String?
  public var source: String
  public var recipients: [String]
  public var disableTls: Bool
  public var events: NotificationEvents?

  public init(
    host: String, port: Int, user: String? = nil, password: String? = nil, token: String? = nil,
    source: String, recipients: [String], disableTls: Bool = false,
    events: NotificationEvents? = .defaults
  ) {
    self.host = host
    self.port = port
    self.user = user
    self.password = password
    self.token = token
    self.source = source
    self.recipients = recipients
    self.disableTls = disableTls
    self.events = events
  }
}

public struct SlackNotificationConfiguration: Codable, Hashable, Sendable {
  public var token: String?
  public var botName: String?
  public var icon: String?
  public var color: String?
  public var title: String?
  public var channel: String?
  public var threadTs: String?
  public var events: NotificationEvents?

  public init(
    token: String? = nil, botName: String? = nil, icon: String? = nil, color: String? = nil,
    title: String? = nil, channel: String? = nil, threadTs: String? = nil,
    events: NotificationEvents? = .defaults
  ) {
    self.token = token
    self.botName = botName
    self.icon = icon
    self.color = color
    self.title = title
    self.channel = channel
    self.threadTs = threadTs
    self.events = events
  }
}

public struct NtfyNotificationConfiguration: Codable, Hashable, Sendable {
  public var host: String
  public var port: Int
  public var topic: String
  public var username: String?
  public var password: String?
  public var title: String?
  public var priority: String?
  public var tags: [String]?
  public var icon: String?
  public var cache: Bool
  public var firebase: Bool
  public var disableTls: Bool
  public var disableTlsVerification: Bool
  public var events: NotificationEvents?

  public init(
    host: String, port: Int, topic: String, username: String? = nil, password: String? = nil,
    title: String? = nil, priority: String? = nil, tags: [String]? = nil, icon: String? = nil,
    cache: Bool = true, firebase: Bool = true, disableTls: Bool = false,
    disableTlsVerification: Bool = false, events: NotificationEvents? = .defaults
  ) {
    self.host = host
    self.port = port
    self.topic = topic
    self.username = username
    self.password = password
    self.title = title
    self.priority = priority
    self.tags = tags
    self.icon = icon
    self.cache = cache
    self.firebase = firebase
    self.disableTls = disableTls
    self.disableTlsVerification = disableTlsVerification
    self.events = events
  }
}

public struct PushoverNotificationConfiguration: Codable, Hashable, Sendable {
  public var token: String?
  public var user: String
  public var devices: [String]?
  public var priority: Int
  public var title: String?
  public var events: NotificationEvents?

  public init(
    token: String? = nil, user: String, devices: [String]? = nil, priority: Int = 0,
    title: String? = nil, events: NotificationEvents? = .defaults
  ) {
    self.token = token
    self.user = user
    self.devices = devices
    self.priority = priority
    self.title = title
    self.events = events
  }
}

public struct GotifyNotificationConfiguration: Codable, Hashable, Sendable {
  public var host: String
  public var port: Int?
  public var token: String?
  public var path: String?
  public var priority: Int?
  public var title: String?
  public var disableTls: Bool
  public var insecureSkipVerify: Bool
  public var useHeader: Bool
  public var events: NotificationEvents?

  public init(
    host: String, port: Int? = nil, token: String? = nil, path: String? = nil, priority: Int? = nil,
    title: String? = nil, disableTls: Bool = false, insecureSkipVerify: Bool = false,
    useHeader: Bool = false, events: NotificationEvents? = .defaults
  ) {
    self.host = host
    self.port = port
    self.token = token
    self.path = path
    self.priority = priority
    self.title = title
    self.disableTls = disableTls
    self.insecureSkipVerify = insecureSkipVerify
    self.useHeader = useHeader
    self.events = events
  }
}

public struct MatrixNotificationConfiguration: Codable, Hashable, Sendable {
  public var host: String
  public var port: Int?
  public var rooms: String
  public var username: String?
  public var password: String?
  public var disableTlsVerification: Bool
  public var events: NotificationEvents?

  public init(
    host: String, port: Int? = nil, rooms: String, username: String? = nil, password: String? = nil,
    disableTlsVerification: Bool = false, events: NotificationEvents? = .defaults
  ) {
    self.host = host
    self.port = port
    self.rooms = rooms
    self.username = username
    self.password = password
    self.disableTlsVerification = disableTlsVerification
    self.events = events
  }
}

public struct GoogleChatNotificationConfiguration: Codable, Hashable, Sendable {
  public var webhookUrl: String?
  public var events: NotificationEvents?

  public init(webhookUrl: String? = nil, events: NotificationEvents? = .defaults) {
    self.webhookUrl = webhookUrl
    self.events = events
  }
}

public struct GenericNotificationConfiguration: Codable, Hashable, Sendable {
  public var webhookUrl: String
  public var method: String?
  public var contentType: String?
  public var titleKey: String?
  public var messageKey: String?
  public var customHeaders: [String: String]?
  public var disableTls: Bool
  public var events: NotificationEvents?
  public var successBodyContains: String?
  public var payloadTemplate: String?

  public init(
    webhookUrl: String, method: String? = nil, contentType: String? = nil, titleKey: String? = nil,
    messageKey: String? = nil, customHeaders: [String: String]? = nil, disableTls: Bool = false,
    events: NotificationEvents? = .defaults, successBodyContains: String? = nil,
    payloadTemplate: String? = nil
  ) {
    self.webhookUrl = webhookUrl
    self.method = method
    self.contentType = contentType
    self.titleKey = titleKey
    self.messageKey = messageKey
    self.customHeaders = customHeaders
    self.disableTls = disableTls
    self.events = events
    self.successBodyContains = successBodyContains
    self.payloadTemplate = payloadTemplate
  }
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

  fileprivate static func decode(provider: NotificationProvider, from decoder: Decoder) throws
    -> Self
  {
    switch provider {
    case .discord: .discord(try DiscordNotificationConfiguration(from: decoder))
    case .email: .email(try EmailNotificationConfiguration(from: decoder))
    case .telegram: .telegram(try TelegramNotificationConfiguration(from: decoder))
    case .signal: .signal(try SignalNotificationConfiguration(from: decoder))
    case .slack: .slack(try SlackNotificationConfiguration(from: decoder))
    case .ntfy: .ntfy(try NtfyNotificationConfiguration(from: decoder))
    case .pushover: .pushover(try PushoverNotificationConfiguration(from: decoder))
    case .gotify: .gotify(try GotifyNotificationConfiguration(from: decoder))
    case .matrix: .matrix(try MatrixNotificationConfiguration(from: decoder))
    case .googlechat: .googlechat(try GoogleChatNotificationConfiguration(from: decoder))
    case .generic: .generic(try GenericNotificationConfiguration(from: decoder))
    }
  }

  fileprivate func encode(to encoder: Encoder) throws {
    switch self {
    case .discord(let value): try value.encode(to: encoder)
    case .email(let value): try value.encode(to: encoder)
    case .telegram(let value): try value.encode(to: encoder)
    case .signal(let value): try value.encode(to: encoder)
    case .slack(let value): try value.encode(to: encoder)
    case .ntfy(let value): try value.encode(to: encoder)
    case .pushover(let value): try value.encode(to: encoder)
    case .gotify(let value): try value.encode(to: encoder)
    case .matrix(let value): try value.encode(to: encoder)
    case .googlechat(let value): try value.encode(to: encoder)
    case .generic(let value): try value.encode(to: encoder)
    }
  }

  fileprivate func sanitizedForUpdate() -> Self {
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
    config = try NotificationConfiguration.decode(
      provider: provider, from: container.superDecoder(forKey: .config))
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(provider, forKey: .provider)
    try container.encode(enabled, forKey: .enabled)
    try config.encode(to: container.superEncoder(forKey: .config))
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
    config = try NotificationConfiguration.decode(
      provider: provider, from: container.superDecoder(forKey: .config))
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(provider, forKey: .provider)
    try container.encode(enabled, forKey: .enabled)
    try config.sanitizedForUpdate().encode(to: container.superEncoder(forKey: .config))
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
