import Foundation

/// DeploymentSnippetFile is one generated PEM file used by edge mTLS deployments.
public struct DeploymentSnippetFile: Codable, Hashable, Sendable {
  public var name: String
  public var content: String?
  public var downloadUrl: String?
  public var sensitive: Bool?
  public var containerPath: String
  public var permissions: String

  public init(
    name: String,
    content: String? = nil,
    downloadUrl: String? = nil,
    sensitive: Bool? = nil,
    containerPath: String,
    permissions: String
  ) {
    self.name = name
    self.content = content
    self.downloadUrl = downloadUrl
    self.sensitive = sensitive
    self.containerPath = containerPath
    self.permissions = permissions
  }
}

/// DeploymentSnippetMTLS bundles Arcane-generated mTLS deployment assets.
public struct DeploymentSnippetMTLS: Codable, Hashable, Sendable {
  public var dockerRun: String
  public var dockerCompose: String
  public var files: [DeploymentSnippetFile]
  public var hostDirHint: String

  public init(
    dockerRun: String,
    dockerCompose: String,
    files: [DeploymentSnippetFile] = [],
    hostDirHint: String
  ) {
    self.dockerRun = dockerRun
    self.dockerCompose = dockerCompose
    self.files = files
    self.hostDirHint = hostDirHint
  }
}

/// DeploymentSnippet is the response payload for ``GET environments/{id}/deployment``.
public struct DeploymentSnippet: Codable, Hashable, Sendable {
  public var dockerRun: String
  public var dockerCompose: String
  public var mtls: DeploymentSnippetMTLS?

  public init(
    dockerRun: String,
    dockerCompose: String,
    mtls: DeploymentSnippetMTLS? = nil
  ) {
    self.dockerRun = dockerRun
    self.dockerCompose = dockerCompose
    self.mtls = mtls
  }
}
