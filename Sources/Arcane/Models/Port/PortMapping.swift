import Foundation

/// A port mapping between a container and its host.
public struct PortMapping: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var containerId: String
  public var containerName: String
  public var hostIp: String?
  public var hostPort: Int?
  public var containerPort: Int
  public var protocolName: String
  public var isPublished: Bool

  private enum CodingKeys: String, CodingKey {
    case id
    case containerId
    case containerName
    case hostIp
    case hostPort
    case containerPort
    case protocolName = "protocol"
    case isPublished
  }

  public init(
    id: String,
    containerId: String,
    containerName: String,
    hostIp: String? = nil,
    hostPort: Int? = nil,
    containerPort: Int,
    protocolName: String,
    isPublished: Bool = false
  ) {
    self.id = id
    self.containerId = containerId
    self.containerName = containerName
    self.hostIp = hostIp
    self.hostPort = hostPort
    self.containerPort = containerPort
    self.protocolName = protocolName
    self.isPublished = isPublished
  }
}
