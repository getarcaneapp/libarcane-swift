import Foundation

/// Request body for the image pull endpoint.
public struct ImagePullOptions: Codable, Hashable, Sendable {
  public var imageName: String
  public var tag: String?
  public var auth: ContainerRegistryCredential?
  public var credentials: [ContainerRegistryCredential]?

  public init(
    imageName: String,
    tag: String? = nil,
    auth: ContainerRegistryCredential? = nil,
    credentials: [ContainerRegistryCredential]? = nil
  ) {
    self.imageName = imageName
    self.tag = tag
    self.auth = auth
    self.credentials = credentials
  }
}
