import Foundation

public struct DiscordNotificationConfiguration: Codable, Hashable, Sendable {
  public var webhookId: String
  public var token: String?
  public var username: String?
  public var avatarUrl: String?
  public var events: NotificationEvents?

  public init(
    webhookId: String,
    token: String? = nil,
    username: String? = nil,
    avatarUrl: String? = nil,
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
    smtpHost: String,
    smtpPort: Int,
    smtpUsername: String,
    smtpPassword: String? = nil,
    fromAddress: String,
    toAddresses: [String],
    tlsMode: EmailTLSMode,
    authMode: EmailAuthMode? = .auto,
    events: NotificationEvents? = .defaults
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
    botToken: String? = nil,
    chatIds: [String],
    preview: Bool = true,
    notification: Bool = true,
    parseMode: String? = nil,
    title: String? = nil,
    events: NotificationEvents? = .defaults
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
    host: String,
    port: Int,
    user: String? = nil,
    password: String? = nil,
    token: String? = nil,
    source: String,
    recipients: [String],
    disableTls: Bool = false,
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
    token: String? = nil,
    botName: String? = nil,
    icon: String? = nil,
    color: String? = nil,
    title: String? = nil,
    channel: String? = nil,
    threadTs: String? = nil,
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
    host: String,
    port: Int,
    topic: String,
    username: String? = nil,
    password: String? = nil,
    title: String? = nil,
    priority: String? = nil,
    tags: [String]? = nil,
    icon: String? = nil,
    cache: Bool = true,
    firebase: Bool = true,
    disableTls: Bool = false,
    disableTlsVerification: Bool = false,
    events: NotificationEvents? = .defaults
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
    token: String? = nil,
    user: String,
    devices: [String]? = nil,
    priority: Int = 0,
    title: String? = nil,
    events: NotificationEvents? = .defaults
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
    host: String,
    port: Int? = nil,
    token: String? = nil,
    path: String? = nil,
    priority: Int? = nil,
    title: String? = nil,
    disableTls: Bool = false,
    insecureSkipVerify: Bool = false,
    useHeader: Bool = false,
    events: NotificationEvents? = .defaults
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
    host: String,
    port: Int? = nil,
    rooms: String,
    username: String? = nil,
    password: String? = nil,
    disableTlsVerification: Bool = false,
    events: NotificationEvents? = .defaults
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
    webhookUrl: String,
    method: String? = nil,
    contentType: String? = nil,
    titleKey: String? = nil,
    messageKey: String? = nil,
    customHeaders: [String: String]? = nil,
    disableTls: Bool = false,
    events: NotificationEvents? = .defaults,
    successBodyContains: String? = nil,
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
