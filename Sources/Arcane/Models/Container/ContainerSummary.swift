import Foundation

/// A container summary as returned by the list endpoint.
public struct ContainerSummary: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var names: [String]
  public var image: String
  public var imageId: String
  public var command: String
  public var created: Int64
  public var ports: [ContainerPort]
  public var labels: [String: String]
  public var state: String
  public var status: String
  public var hostConfig: ContainerHostConfig
  public var networkSettings: ContainerNetworkSettings
  public var mounts: [ContainerMount]
  public var iconLightUrl: String?
  public var iconDarkUrl: String?
  public var updateInfo: ImageUpdateInfo?
  public var redeployDisabled: Bool?

  private enum CodingKeys: String, CodingKey {
    case id
    case names
    case image
    case imageId
    case command
    case created
    case ports
    case labels
    case state
    case status
    case hostConfig
    case networkSettings
    case mounts
    case iconLightUrl
    case iconDarkUrl
    case updateInfo
    case redeployDisabled
  }

  public init(
    id: String,
    names: [String] = [],
    image: String,
    imageId: String,
    command: String = "",
    created: Int64 = 0,
    ports: [ContainerPort] = [],
    labels: [String: String] = [:],
    state: String,
    status: String,
    hostConfig: ContainerHostConfig = .init(),
    networkSettings: ContainerNetworkSettings = .init(),
    mounts: [ContainerMount] = [],
    iconLightUrl: String? = nil,
    iconDarkUrl: String? = nil,
    updateInfo: ImageUpdateInfo? = nil,
    redeployDisabled: Bool? = nil
  ) {
    self.id = id
    self.names = names
    self.image = image
    self.imageId = imageId
    self.command = command
    self.created = created
    self.ports = ports
    self.labels = labels
    self.state = state
    self.status = status
    self.hostConfig = hostConfig
    self.networkSettings = networkSettings
    self.mounts = mounts
    self.iconLightUrl = iconLightUrl
    self.iconDarkUrl = iconDarkUrl
    self.updateInfo = updateInfo
    self.redeployDisabled = redeployDisabled
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    names = try container.decode([String].self, forKey: .names)
    image = try container.decode(String.self, forKey: .image)
    imageId = try container.decode(String.self, forKey: .imageId)
    command = try container.decode(String.self, forKey: .command)
    created = try container.decode(Int64.self, forKey: .created)
    ports = try container.decode([ContainerPort].self, forKey: .ports)
    labels = try container.decodeEmptyDictionaryIfPresent([String: String].self, forKey: .labels)
    state = try container.decode(String.self, forKey: .state)
    status = try container.decode(String.self, forKey: .status)
    hostConfig = try container.decode(ContainerHostConfig.self, forKey: .hostConfig)
    networkSettings = try container.decode(ContainerNetworkSettings.self, forKey: .networkSettings)
    mounts = try container.decode([ContainerMount].self, forKey: .mounts)
    iconLightUrl = try container.decodeIfPresent(String.self, forKey: .iconLightUrl)
    iconDarkUrl = try container.decodeIfPresent(String.self, forKey: .iconDarkUrl)
    updateInfo = try container.decodeIfPresent(ImageUpdateInfo.self, forKey: .updateInfo)
    redeployDisabled = try container.decodeIfPresent(Bool.self, forKey: .redeployDisabled)
  }
}

/// A group of container summaries, e.g. by Compose project.
public struct ContainerSummaryGroup: Codable, Hashable, Sendable {
  public var groupName: String
  public var items: [ContainerSummary]

  public init(groupName: String, items: [ContainerSummary] = []) {
    self.groupName = groupName
    self.items = items
  }

  private enum CodingKeys: String, CodingKey {
    case groupName, items
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    groupName = try container.decode(String.self, forKey: .groupName)
    items = try container.decode(LossyContainerSummaryArray.self, forKey: .items).elements
  }
}

struct LossyContainerSummaryArray: Decodable, Sendable {
  let elements: [ContainerSummary]

  init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    var elements: [ContainerSummary] = []
    while !container.isAtEnd {
      let elementDecoder = try container.superDecoder()
      if let element = try? ContainerSummary(from: elementDecoder) {
        elements.append(element)
      }
    }
    self.elements = elements
  }
}

/// Counts of containers by status.
public struct ContainerStatusCounts: Codable, Hashable, Sendable {
  public var runningContainers: Int
  public var stoppedContainers: Int
  public var totalContainers: Int

  public init(runningContainers: Int = 0, stoppedContainers: Int = 0, totalContainers: Int = 0) {
    self.runningContainers = runningContainers
    self.stoppedContainers = stoppedContainers
    self.totalContainers = totalContainers
  }
}

/// Result of a container batch action (start/stop/etc).
public struct ContainerActionResult: Codable, Hashable, Sendable {
  public var started: [String]?
  public var stopped: [String]?
  public var failed: [String]?
  public var success: Bool
  public var errors: [String]?
  public var activityID: String?

  public init(
    started: [String]? = nil,
    stopped: [String]? = nil,
    failed: [String]? = nil,
    success: Bool = false,
    errors: [String]? = nil,
    activityID: String? = nil
  ) {
    self.started = started
    self.stopped = stopped
    self.failed = failed
    self.success = success
    self.errors = errors
    self.activityID = activityID
  }

  private enum CodingKeys: String, CodingKey {
    case started, stopped, failed, success, errors
    case activityID = "activityId"
  }
}

/// A newly created container.
public struct ContainerCreated: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var name: String
  public var image: String
  public var status: String
  public var created: String

  public init(id: String, name: String, image: String, status: String, created: String) {
    self.id = id
    self.name = name
    self.image = image
    self.status = status
    self.created = created
  }
}
