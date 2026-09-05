import Foundation

/// Typed bind or volume mount.
public struct ContainerMountCreate: Codable, Hashable, Sendable {
  public var type: String
  public var source: String
  public var target: String
  public var readOnly: Bool?

  public init(
    type: String,
    source: String,
    target: String,
    readOnly: Bool? = nil
  ) {
    self.type = type
    self.source = source
    self.target = target
    self.readOnly = readOnly
  }
}

/// Healthcheck for create/edit. All durations are in seconds, unlike inspect durations.
public struct ContainerHealthcheckCreate: Codable, Hashable, Sendable {
  public var test: [String]?
  public var interval: Int64?
  public var timeout: Int64?
  public var startPeriod: Int64?
  public var startInterval: Int64?
  public var retries: Int?

  public init(
    test: [String]? = nil,
    interval: Int64? = nil,
    timeout: Int64? = nil,
    startPeriod: Int64? = nil,
    startInterval: Int64? = nil,
    retries: Int? = nil
  ) {
    self.test = test
    self.interval = interval
    self.timeout = timeout
    self.startPeriod = startPeriod
    self.startInterval = startInterval
    self.retries = retries
  }
}

/// Host edits: nil preserves a field; empty collections, zero, and false replace it.
public struct HostConfigEdit: Codable, Hashable, Sendable {
  public var binds: [String]?
  public var mounts: [ContainerMountCreate]?
  public var portBindings: [String: [PortBindingCreate]]?
  public var restartPolicy: ContainerRestartPolicyCreate?
  public var privileged: Bool?
  public var capAdd: [String]?
  public var capDrop: [String]?
  public var autoRemove: Bool?
  public var readonlyRootfs: Bool?
  public var memory: Int64?
  public var memorySwap: Int64?
  public var nanoCpus: Int64?
  public var cpuShares: Int64?

  public init(
    binds: [String]? = nil,
    mounts: [ContainerMountCreate]? = nil,
    portBindings: [String: [PortBindingCreate]]? = nil,
    restartPolicy: ContainerRestartPolicyCreate? = nil,
    privileged: Bool? = nil,
    capAdd: [String]? = nil,
    capDrop: [String]? = nil,
    autoRemove: Bool? = nil,
    readonlyRootfs: Bool? = nil,
    memory: Int64? = nil,
    memorySwap: Int64? = nil,
    nanoCpus: Int64? = nil,
    cpuShares: Int64? = nil
  ) {
    self.binds = binds
    self.mounts = mounts
    self.portBindings = portBindings
    self.restartPolicy = restartPolicy
    self.privileged = privileged
    self.capAdd = capAdd
    self.capDrop = capDrop
    self.autoRemove = autoRemove
    self.readonlyRootfs = readonlyRootfs
    self.memory = memory
    self.memorySwap = memorySwap
    self.nanoCpus = nanoCpus
    self.cpuShares = cpuShares
  }
}

/// Configuration changes applied by recreating a container. Nil fields are omitted and preserved.
public struct ContainerEdit: Codable, Hashable, Sendable {
  public var name: String?
  public var image: String?
  public var workingDir: String?
  public var user: String?
  public var command: [String]?
  public var entrypoint: [String]?
  public var environment: [String]?
  public var labels: [String: String]?
  public var healthcheck: ContainerHealthcheckCreate?
  public var clearHealthcheck: Bool?
  public var hostConfig: HostConfigEdit?
  public var networkingConfig: NetworkingConfigCreate?
  public var credentials: [ContainerRegistryCredential]?

  public init(
    name: String? = nil,
    image: String? = nil,
    workingDir: String? = nil,
    user: String? = nil,
    command: [String]? = nil,
    entrypoint: [String]? = nil,
    environment: [String]? = nil,
    labels: [String: String]? = nil,
    healthcheck: ContainerHealthcheckCreate? = nil,
    clearHealthcheck: Bool? = nil,
    hostConfig: HostConfigEdit? = nil,
    networkingConfig: NetworkingConfigCreate? = nil,
    credentials: [ContainerRegistryCredential]? = nil
  ) {
    self.name = name
    self.image = image
    self.workingDir = workingDir
    self.user = user
    self.command = command
    self.entrypoint = entrypoint
    self.environment = environment
    self.labels = labels
    self.healthcheck = healthcheck
    self.clearHealthcheck = clearHealthcheck
    self.hostConfig = hostConfig
    self.networkingConfig = networkingConfig
    self.credentials = credentials
  }
}

/// Editable snapshot. Omitted boolean flags from the server have false semantics.
public struct ContainerEditConfig: Codable, Hashable, Sendable {
  public var id: String
  public var name: String
  public var image: String
  public var hostConfig: HostConfigCreate
  public var running: Bool
  public var command: [String]?
  public var entrypoint: [String]?
  public var workingDir: String?
  public var user: String?
  public var environment: [String]?
  public var labels: [String: String]?
  public var healthcheck: ContainerHealthcheckCreate?
  public var networks: [String: EndpointSettingsCreate]?
  public var isCompose: Bool?
  public var composeProject: String?
  public var editDisabled: Bool?

  public init(
    id: String,
    name: String,
    image: String,
    hostConfig: HostConfigCreate,
    running: Bool,
    command: [String]? = nil,
    entrypoint: [String]? = nil,
    workingDir: String? = nil,
    user: String? = nil,
    environment: [String]? = nil,
    labels: [String: String]? = nil,
    healthcheck: ContainerHealthcheckCreate? = nil,
    networks: [String: EndpointSettingsCreate]? = nil,
    isCompose: Bool? = nil,
    composeProject: String? = nil,
    editDisabled: Bool? = nil
  ) {
    self.id = id
    self.name = name
    self.image = image
    self.hostConfig = hostConfig
    self.running = running
    self.command = command
    self.entrypoint = entrypoint
    self.workingDir = workingDir
    self.user = user
    self.environment = environment
    self.labels = labels
    self.healthcheck = healthcheck
    self.networks = networks
    self.isCompose = isCompose
    self.composeProject = composeProject
    self.editDisabled = editDisabled
  }
}

/// Options for creating an image from a container filesystem.
public struct ContainerCommitRequest: Codable, Hashable, Sendable {
  public var repository: String?
  public var tag: String?
  public var comment: String?
  public var author: String?
  public var changes: [String]?
  public var noPause: Bool?

  public init(
    repository: String? = nil,
    tag: String? = nil,
    comment: String? = nil,
    author: String? = nil,
    changes: [String]? = nil,
    noPause: Bool? = nil
  ) {
    self.repository = repository
    self.tag = tag
    self.comment = comment
    self.author = author
    self.changes = changes
    self.noPause = noPause
  }
}

/// Committed image identifier.
public struct ContainerCommitResult: Codable, Hashable, Sendable {
  public var id: String

  public init(
    id: String
  ) {
    self.id = id
  }
}

/// Containers to convert to a Compose document.
public struct ContainerGenerateComposeRequest: Codable, Hashable, Sendable {
  public var containerIds: [String]

  public init(
    containerIds: [String]
  ) {
    self.containerIds = containerIds
  }
}

/// Generated Compose document.
public struct ContainerGenerateComposeResponse: Codable, Hashable, Sendable {
  public var composeContent: String

  public init(
    composeContent: String
  ) {
    self.composeContent = composeContent
  }
}
