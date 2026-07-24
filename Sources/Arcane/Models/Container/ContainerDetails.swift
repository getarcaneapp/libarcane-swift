import Foundation

/// Detailed container information.
public struct ContainerDetails: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var name: String
  public var image: String
  public var imageId: String
  public var created: String
  public var state: ContainerState
  public var config: ContainerConfig
  public var hostConfig: ContainerHostConfig
  public var networkSettings: ContainerNetworkSettings
  public var ports: [ContainerPort]
  public var mounts: [ContainerMount]
  public var labels: [String: String]?
  public var composeInfo: ContainerComposeInfo?
  public var iconLightUrl: String?
  public var iconDarkUrl: String?
  public var redeployDisabled: Bool?
  public var activityID: String?

  public init(
    id: String,
    name: String = "",
    image: String = "",
    imageId: String = "",
    created: String = "",
    state: ContainerState = .init(status: "", running: false),
    config: ContainerConfig = .init(),
    hostConfig: ContainerHostConfig = .init(),
    networkSettings: ContainerNetworkSettings = .init(),
    ports: [ContainerPort] = [],
    mounts: [ContainerMount] = [],
    labels: [String: String]? = nil,
    composeInfo: ContainerComposeInfo? = nil,
    iconLightUrl: String? = nil,
    iconDarkUrl: String? = nil,
    redeployDisabled: Bool? = nil,
    activityID: String? = nil
  ) {
    self.id = id
    self.name = name
    self.image = image
    self.imageId = imageId
    self.created = created
    self.state = state
    self.config = config
    self.hostConfig = hostConfig
    self.networkSettings = networkSettings
    self.ports = ports
    self.mounts = mounts
    self.labels = labels
    self.composeInfo = composeInfo
    self.iconLightUrl = iconLightUrl
    self.iconDarkUrl = iconDarkUrl
    self.redeployDisabled = redeployDisabled
    self.activityID = activityID
  }

  private enum CodingKeys: String, CodingKey {
    case id, name, image, imageId, created, state, config, hostConfig, networkSettings
    case ports, mounts, labels, composeInfo, iconLightUrl, iconDarkUrl, redeployDisabled
    case activityID = "activityId"
  }
}

/// Paginated container list response. Includes optional groups + status counts.
public struct ContainerListResponse: Decodable, Sendable {
  public var success: Bool
  public var data: [ContainerSummary]
  public var groups: [ContainerSummaryGroup]?
  public var counts: ContainerStatusCounts
  public var pagination: PaginationResponse

  public init(
    success: Bool,
    data: [ContainerSummary] = [],
    groups: [ContainerSummaryGroup]? = nil,
    counts: ContainerStatusCounts = .init(),
    pagination: PaginationResponse
  ) {
    self.success = success
    self.data = data
    self.groups = groups
    self.counts = counts
    self.pagination = pagination
  }
}
