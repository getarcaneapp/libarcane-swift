import Foundation

/// Feature flag advertised in `/app-version` `enabledFeatures` when the server
/// can pair mobile devices for native push notifications.
public let mobilePushFeature = "mobile-push-v1"

/// Notification event keys accepted in `MobilePushDevice.events`.
public enum MobilePushEvent: String, CaseIterable, Codable, Hashable, Sendable {
  case imageUpdate = "image_update"
  case containerUpdate = "container_update"
  case vulnerabilityFound = "vulnerability_found"
  case pruneReport = "prune_report"
  case autoHeal = "auto_heal"
}

/// A device registered with the Arcane server for mobile push.
public struct MobilePushDevice: Codable, Hashable, Identifiable, Sendable {
  public var id: String
  public var label: String
  public var events: [String: Bool]
  public var environmentIds: [String]
  public var createdAt: Date
  public var lastSeenAt: Date?

  public init(
    id: String,
    label: String,
    events: [String: Bool] = [:],
    environmentIds: [String] = [],
    createdAt: Date,
    lastSeenAt: Date? = nil
  ) {
    self.id = id
    self.label = label
    self.events = events
    self.environmentIds = environmentIds
    self.createdAt = createdAt
    self.lastSeenAt = lastSeenAt
  }

  public func isEnabled(_ event: MobilePushEvent) -> Bool {
    events[event.rawValue] ?? false
  }
}

/// Server-wide mobile push status plus the caller's devices.
public struct MobilePushStatus: Codable, Hashable, Sendable {
  public var enabled: Bool
  public var channelId: String?
  public var relayUrl: String
  public var devices: [MobilePushDevice]

  public init(enabled: Bool, channelId: String? = nil, relayUrl: String, devices: [MobilePushDevice] = []) {
    self.enabled = enabled
    self.channelId = channelId
    self.relayUrl = relayUrl
    self.devices = devices
  }
}

/// Short-lived token the app presents to the push relay's `POST /v1/pair`.
public struct MobilePushPairingToken: Codable, Hashable, Sendable {
  public var token: String
  public var channelId: String
  public var expiresAt: Date

  public init(token: String, channelId: String, expiresAt: Date) {
    self.token = token
    self.channelId = channelId
    self.expiresAt = expiresAt
  }
}

public struct MobilePushRegisterDevice: Codable, Hashable, Sendable {
  public var recipientId: String
  public var label: String
  public var events: [String: Bool]?
  public var environmentIds: [String]?

  public init(recipientId: String, label: String, events: [String: Bool]? = nil, environmentIds: [String]? = nil) {
    self.recipientId = recipientId
    self.label = label
    self.events = events
    self.environmentIds = environmentIds
  }
}

public struct MobilePushUpdateDevice: Codable, Hashable, Sendable {
  public var label: String?
  public var events: [String: Bool]?
  public var environmentIds: [String]?

  public init(label: String? = nil, events: [String: Bool]? = nil, environmentIds: [String]? = nil) {
    self.label = label
    self.events = events
    self.environmentIds = environmentIds
  }
}

/// Typed deep link carried in a push payload.
public struct MobilePushRoute: Codable, Hashable, Sendable {
  public enum Kind: String, Codable, Hashable, Sendable {
    case tab
    case container
    case image
    case activities
    case events
    case environment
  }

  public var kind: Kind
  public var tab: String?
  public var environmentId: String?
  public var id: String?

  public init(kind: Kind, tab: String? = nil, environmentId: String? = nil, id: String? = nil) {
    self.kind = kind
    self.tab = tab
    self.environmentId = environmentId
    self.id = id
  }
}

public struct MobilePushResource: Codable, Hashable, Sendable {
  public var kind: String
  public var id: String
  public var name: String?

  public init(kind: String, id: String, name: String? = nil) {
    self.kind = kind
    self.id = id
    self.name = name
  }
}

/// The `arcane` dictionary inside an APNs payload delivered by the relay.
public struct MobilePushPayload: Codable, Hashable, Sendable {
  public var v: Int
  public var eventId: String
  public var occurredAt: Date
  public var type: String
  public var severity: String
  public var environmentId: String?
  public var environmentName: String?
  public var resource: MobilePushResource?
  public var route: MobilePushRoute
  public var channelId: String

  public init(
    v: Int = 1,
    eventId: String,
    occurredAt: Date,
    type: String,
    severity: String,
    environmentId: String? = nil,
    environmentName: String? = nil,
    resource: MobilePushResource? = nil,
    route: MobilePushRoute,
    channelId: String
  ) {
    self.v = v
    self.eventId = eventId
    self.occurredAt = occurredAt
    self.type = type
    self.severity = severity
    self.environmentId = environmentId
    self.environmentName = environmentName
    self.resource = resource
    self.route = route
    self.channelId = channelId
  }

  /// Decodes the `arcane` object from a `UNNotification` `userInfo` dictionary.
  public init?(userInfo: [AnyHashable: Any]) {
    guard let arcane = userInfo["arcane"],
      JSONSerialization.isValidJSONObject(arcane),
      let data = try? JSONSerialization.data(withJSONObject: arcane),
      let decoded = try? ArcaneJSON.makeDecoder().decode(MobilePushPayload.self, from: data)
    else { return nil }
    self = decoded
  }
}
