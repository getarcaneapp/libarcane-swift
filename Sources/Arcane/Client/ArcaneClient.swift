import Foundation

public struct ArcaneClient: Sendable {
  /// Package-wide client configuration shared by all service entry points.
  /// Most apps only need `baseURL`, a `TokenStore`, and optionally a custom
  /// `URLSession` tuned for their networking environment.
  public struct Configuration: Sendable {
    public var baseURL: URL
    public var tokenStore: any TokenStore
    public var apiKey: String?
    public var defaultEnvironmentID: EnvironmentID
    /// Inject an app-owned session when you need custom connectivity,
    /// caching, cookies, or TLS behavior instead of relying on `.shared`.
    public var urlSession: URLSession
    public var retryPolicy: RetryPolicy
    public var jsonDecoder: JSONDecoder
    public var jsonEncoder: JSONEncoder

    public init(
      baseURL: URL,
      tokenStore: any TokenStore = InMemoryTokenStore(),
      apiKey: String? = nil,
      defaultEnvironmentID: EnvironmentID = .localDocker,
      urlSession: URLSession = .shared,
      retryPolicy: RetryPolicy = .default
    ) {
      self.baseURL = baseURL
      self.tokenStore = tokenStore
      self.apiKey = apiKey
      self.defaultEnvironmentID = defaultEnvironmentID
      self.urlSession = urlSession
      self.retryPolicy = retryPolicy
      self.jsonDecoder = ArcaneJSON.makeDecoder()
      self.jsonEncoder = ArcaneJSON.makeEncoder()
    }
  }

  public let configuration: Configuration
  public let authManager: AuthManager
  /// Low-level request/response transport used by the SDK's higher-level
  /// services. Reach for this when you need raw bytes, multipart uploads, or
  /// a not-yet-wrapped endpoint without re-implementing auth and retry logic.
  public let transport: ArcaneURLSessionTransport
  /// Convenience REST facade over `transport` for standard Arcane JSON
  /// endpoints that already follow the `{ success, data }` response envelope.
  public let rest: RESTService

  public let auth: AuthService
  public let passkeys: PasskeysService
  public let users: UsersService
  public let apiKeys: APIKeysService
  public let roles: RolesService
  public let oidcRoleMappings: OidcRoleMappingsService
  public let environments: EnvironmentsService
  public let containers: ContainersService
  public let images: ImagesService
  public let volumes: VolumesService
  public let networks: NetworksService
  public let projects: ProjectsService
  public let swarm: SwarmService
  public let system: SystemService
  public let dashboard: DashboardService
  public let activities: ActivitiesService
  public let events: EventsService
  public let webhooks: WebhooksService
  public let notifications: NotificationsService
  public let templates: TemplatesService
  public let variables: VariablesService
  public let registries: ContainerRegistriesService
  public let gitops: GitOpsService
  public let builds: BuildsService
  public let jobs: JobsService
  public let settings: SettingsService
  public let updater: UpdaterService
  public let vulnerabilities: VulnerabilitiesService
  public let ports: PortsService
  public let version: VersionService
  public let mobilePush: MobilePushService

  public init(configuration: Configuration) {
    let authManager = AuthManager(
      baseURL: configuration.baseURL,
      tokenStore: configuration.tokenStore,
      apiKey: configuration.apiKey,
      urlSession: configuration.urlSession,
      decoder: configuration.jsonDecoder,
      encoder: configuration.jsonEncoder
    )
    let transport = ArcaneURLSessionTransport(
      baseURL: configuration.baseURL,
      session: configuration.urlSession,
      authManager: authManager,
      retryPolicy: configuration.retryPolicy,
      decoder: configuration.jsonDecoder,
      encoder: configuration.jsonEncoder
    )
    self.init(configuration: configuration, authManager: authManager, transport: transport)
  }

  private init(
    configuration: Configuration,
    authManager: AuthManager,
    transport: ArcaneURLSessionTransport
  ) {
    self.configuration = configuration
    self.authManager = authManager
    self.transport = transport
    self.rest = RESTService(
      transport: transport, defaultEnvironmentID: configuration.defaultEnvironmentID)
    self.auth = AuthService(
      transport: transport,
      authManager: authManager,
      decoder: configuration.jsonDecoder,
      encoder: configuration.jsonEncoder
    )
    self.passkeys = PasskeysService(rest: rest, authManager: authManager)
    self.users = UsersService(rest: rest)
    self.apiKeys = APIKeysService(rest: rest)
    self.roles = RolesService(rest: rest)
    self.oidcRoleMappings = OidcRoleMappingsService(rest: rest)
    self.environments = EnvironmentsService(rest: rest)
    self.containers = ContainersService(rest: rest)
    self.images = ImagesService(rest: rest)
    self.volumes = VolumesService(rest: rest)
    self.networks = NetworksService(rest: rest)
    self.projects = ProjectsService(rest: rest)
    self.swarm = SwarmService(rest: rest)
    self.system = SystemService(rest: rest)
    self.dashboard = DashboardService(rest: rest)
    self.activities = ActivitiesService(rest: rest)
    self.events = EventsService(rest: rest)
    self.webhooks = WebhooksService(rest: rest)
    self.notifications = NotificationsService(rest: rest)
    self.templates = TemplatesService(rest: rest)
    self.variables = VariablesService(rest: rest)
    self.registries = ContainerRegistriesService(rest: rest)
    self.gitops = GitOpsService(rest: rest)
    self.builds = BuildsService(rest: rest)
    self.jobs = JobsService(rest: rest)
    self.settings = SettingsService(rest: rest)
    self.updater = UpdaterService(rest: rest)
    self.vulnerabilities = VulnerabilitiesService(rest: rest)
    self.ports = PortsService(rest: rest)
    self.version = VersionService(rest: rest)
    self.mobilePush = MobilePushService(rest: rest)
  }

  public func scoped(toEnvironment envID: EnvironmentID) -> ArcaneClient {
    var scoped = configuration
    scoped.defaultEnvironmentID = envID
    return ArcaneClient(configuration: scoped, authManager: authManager, transport: transport)
  }

  /// Returns a client whose requests inherit task-scoped API metadata.
  ///
  /// The returned value shares this client's authentication manager and URL
  /// session. Request options are immutable and are reapplied whenever the
  /// transport retries or refreshes credentials.
  public func withRequestOptions(_ options: ArcaneRequestOptions) -> ArcaneClient {
    ArcaneClient(
      configuration: configuration,
      authManager: authManager,
      transport: transport.withRequestOptions(options)
    )
  }

  /// Snapshot of the server's API shape. `.unknown` until the SDK decodes
  /// its first authenticated `User` payload (login, `auth/me`, or an OIDC
  /// callback). Apps that gate UI on RBAC support should check
  /// `.supportsRoleManagement` once the user is authenticated.
  public func serverCapabilities() async -> ServerCapabilities {
    await authManager.currentCapabilities()
  }
}

public enum ArcaneJSON {
  private final class ISO8601ParserCache: @unchecked Sendable {
    private let lock = NSLock()
    private let withFractionalSeconds: ISO8601DateFormatter = {
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      return formatter
    }()
    private let withoutFractionalSeconds: ISO8601DateFormatter = {
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withInternetDateTime]
      return formatter
    }()

    func parse(_ raw: String) -> Date? {
      lock.lock()
      defer { lock.unlock() }
      return withFractionalSeconds.date(from: raw)
        ?? withoutFractionalSeconds.date(from: raw)
    }
  }

  private static let iso8601Parsers = ISO8601ParserCache()

  public static func makeDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let raw = try container.decode(String.self)
      if let date = iso8601Parsers.parse(raw) {
        return date
      }
      throw DecodingError.dataCorruptedError(
        in: container, debugDescription: "Invalid ISO8601 date: \(raw)")
    }
    return decoder
  }

  public static func makeEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return encoder
  }
}
