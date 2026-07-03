import Foundation

/// Parsed representation of a `docker run` command.
public struct DockerRunCommand: Codable, Hashable, Sendable {
  public var image: String
  public var name: String?
  public var ports: [String]?
  public var volumes: [String]?
  public var environment: [String]?
  public var networks: [String]?
  public var restart: String?
  public var workdir: String?
  public var user: String?
  public var entrypoint: String?
  public var command: String?
  public var detached: Bool?
  public var interactive: Bool?
  public var tty: Bool?
  public var remove: Bool?
  public var privileged: Bool?
  public var labels: [String]?
  public var healthCheck: String?
  public var memoryLimit: String?
  public var cpuLimit: String?

  public init(
    image: String,
    name: String? = nil,
    ports: [String]? = nil,
    volumes: [String]? = nil,
    environment: [String]? = nil,
    networks: [String]? = nil,
    restart: String? = nil,
    workdir: String? = nil,
    user: String? = nil,
    entrypoint: String? = nil,
    command: String? = nil,
    detached: Bool? = nil,
    interactive: Bool? = nil,
    tty: Bool? = nil,
    remove: Bool? = nil,
    privileged: Bool? = nil,
    labels: [String]? = nil,
    healthCheck: String? = nil,
    memoryLimit: String? = nil,
    cpuLimit: String? = nil
  ) {
    self.image = image
    self.name = name
    self.ports = ports
    self.volumes = volumes
    self.environment = environment
    self.networks = networks
    self.restart = restart
    self.workdir = workdir
    self.user = user
    self.entrypoint = entrypoint
    self.command = command
    self.detached = detached
    self.interactive = interactive
    self.tty = tty
    self.remove = remove
    self.privileged = privileged
    self.labels = labels
    self.healthCheck = healthCheck
    self.memoryLimit = memoryLimit
    self.cpuLimit = cpuLimit
  }
}

/// Body for `POST /environments/{id}/system/convert`.
public struct ConvertDockerRunRequest: Codable, Hashable, Sendable {
  public var dockerRunCommand: String

  public init(dockerRunCommand: String) {
    self.dockerRunCommand = dockerRunCommand
  }
}

/// Result of converting a `docker run` command to compose form.
public struct ConvertDockerRunResponse: Codable, Hashable, Sendable {
  public var success: Bool
  public var dockerCompose: String
  public var envVars: String
  public var serviceName: String

  public init(
    success: Bool,
    dockerCompose: String,
    envVars: String,
    serviceName: String
  ) {
    self.success = success
    self.dockerCompose = dockerCompose
    self.envVars = envVars
    self.serviceName = serviceName
  }
}
