import Foundation

/// Restart policy options for container creation.
public struct ContainerRestartPolicyCreate: Codable, Hashable, Sendable {
  public var name: String?
  public var maximumRetryCount: Int?

  public init(name: String? = nil, maximumRetryCount: Int? = nil) {
    self.name = name
    self.maximumRetryCount = maximumRetryCount
  }
}

/// Host port binding for container creation.
public struct PortBindingCreate: Codable, Hashable, Sendable {
  public var hostIp: String?
  public var hostPort: String?

  public init(hostIp: String? = nil, hostPort: String? = nil) {
    self.hostIp = hostIp
    self.hostPort = hostPort
  }
}

/// Host configuration for container creation.
public struct HostConfigCreate: Codable, Hashable, Sendable {
  public var binds: [String]?
  public var portBindings: [String: [PortBindingCreate]]?
  public var restartPolicy: ContainerRestartPolicyCreate?
  public var networkMode: String?
  public var privileged: Bool?
  public var autoRemove: Bool?
  public var memory: Int64?
  public var memorySwap: Int64?
  public var nanoCpus: Int64?
  public var cpuShares: Int64?
  public var readonlyRootfs: Bool?
  public var publishAllPorts: Bool?
  public var capAdd: [String]?
  public var capDrop: [String]?
  public var mounts: [ContainerMountCreate]?

  public init(
    binds: [String]? = nil,
    portBindings: [String: [PortBindingCreate]]? = nil,
    restartPolicy: ContainerRestartPolicyCreate? = nil,
    networkMode: String? = nil,
    privileged: Bool? = nil,
    autoRemove: Bool? = nil,
    memory: Int64? = nil,
    memorySwap: Int64? = nil,
    nanoCpus: Int64? = nil,
    cpuShares: Int64? = nil,
    readonlyRootfs: Bool? = nil,
    publishAllPorts: Bool? = nil,
    capAdd: [String]? = nil,
    capDrop: [String]? = nil,
    mounts: [ContainerMountCreate]? = nil
  ) {
    self.binds = binds
    self.portBindings = portBindings
    self.restartPolicy = restartPolicy
    self.networkMode = networkMode
    self.privileged = privileged
    self.autoRemove = autoRemove
    self.memory = memory
    self.memorySwap = memorySwap
    self.nanoCpus = nanoCpus
    self.cpuShares = cpuShares
    self.readonlyRootfs = readonlyRootfs
    self.publishAllPorts = publishAllPorts
    self.capAdd = capAdd
    self.capDrop = capDrop
    self.mounts = mounts
  }
}

/// Network endpoint settings for container creation.
public struct EndpointSettingsCreate: Codable, Hashable, Sendable {
  public var aliases: [String]?
  public var ipv4Address: String?
  public var ipv6Address: String?

  public init(aliases: [String]? = nil, ipv4Address: String? = nil, ipv6Address: String? = nil) {
    self.aliases = aliases
    self.ipv4Address = ipv4Address
    self.ipv6Address = ipv6Address
  }
}

/// Network configuration for container creation.
public struct NetworkingConfigCreate: Codable, Hashable, Sendable {
  public var endpointsConfig: [String: EndpointSettingsCreate]?

  public init(endpointsConfig: [String: EndpointSettingsCreate]? = nil) {
    self.endpointsConfig = endpointsConfig
  }
}

/// Container create request body.
public struct ContainerCreate: Codable, Hashable, Sendable {
  public var name: String
  public var image: String
  public var command: [String]?
  public var cmd: [String]?
  public var entrypoint: [String]?
  public var workingDir: String?
  public var user: String?
  public var environment: [String]?
  public var env: [String]?
  public var labels: [String: String]?
  public var healthcheck: ContainerHealthcheckCreate?
  public var exposedPorts: [String: JSONValue]?
  public var hostConfig: HostConfigCreate?
  public var networkingConfig: NetworkingConfigCreate?
  public var hostname: String?
  public var domainname: String?
  public var attachStdout: Bool?
  public var attachStderr: Bool?
  public var attachStdin: Bool?
  public var tty: Bool?
  public var openStdin: Bool?
  public var stdinOnce: Bool?
  public var networkDisabled: Bool?
  public var ports: [String: String]?
  public var volumes: [String]?
  public var networks: [String]?
  public var restartPolicy: String?
  public var privileged: Bool?
  public var autoRemove: Bool?
  public var memory: Int64?
  public var cpus: Double?
  public var credentials: [ContainerRegistryCredential]?

  public init(
    name: String,
    image: String,
    command: [String]? = nil,
    cmd: [String]? = nil,
    entrypoint: [String]? = nil,
    workingDir: String? = nil,
    user: String? = nil,
    environment: [String]? = nil,
    env: [String]? = nil,
    labels: [String: String]? = nil,
    healthcheck: ContainerHealthcheckCreate? = nil,
    exposedPorts: [String: JSONValue]? = nil,
    hostConfig: HostConfigCreate? = nil,
    networkingConfig: NetworkingConfigCreate? = nil,
    hostname: String? = nil,
    domainname: String? = nil,
    attachStdout: Bool? = nil,
    attachStderr: Bool? = nil,
    attachStdin: Bool? = nil,
    tty: Bool? = nil,
    openStdin: Bool? = nil,
    stdinOnce: Bool? = nil,
    networkDisabled: Bool? = nil,
    ports: [String: String]? = nil,
    volumes: [String]? = nil,
    networks: [String]? = nil,
    restartPolicy: String? = nil,
    privileged: Bool? = nil,
    autoRemove: Bool? = nil,
    memory: Int64? = nil,
    cpus: Double? = nil,
    credentials: [ContainerRegistryCredential]? = nil
  ) {
    self.name = name
    self.image = image
    self.command = command
    self.cmd = cmd
    self.entrypoint = entrypoint
    self.workingDir = workingDir
    self.user = user
    self.environment = environment
    self.env = env
    self.labels = labels
    self.healthcheck = healthcheck
    self.exposedPorts = exposedPorts
    self.hostConfig = hostConfig
    self.networkingConfig = networkingConfig
    self.hostname = hostname
    self.domainname = domainname
    self.attachStdout = attachStdout
    self.attachStderr = attachStderr
    self.attachStdin = attachStdin
    self.tty = tty
    self.openStdin = openStdin
    self.stdinOnce = stdinOnce
    self.networkDisabled = networkDisabled
    self.ports = ports
    self.volumes = volumes
    self.networks = networks
    self.restartPolicy = restartPolicy
    self.privileged = privileged
    self.autoRemove = autoRemove
    self.memory = memory
    self.cpus = cpus
    self.credentials = credentials
  }
}
