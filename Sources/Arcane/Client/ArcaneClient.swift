import Foundation

public struct ArcaneClient: Sendable {
    public struct Configuration: Sendable {
        public var baseURL: URL
        public var tokenStore: any TokenStore
        public var apiKey: String?
        public var defaultEnvironmentID: EnvironmentID
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
    public let transport: ArcaneURLSessionTransport
    public let rest: RESTService

    public let auth: AuthService
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
    public let registries: ContainerRegistriesService
    public let gitops: GitOpsService
    public let builds: BuildsService
    public let jobs: JobsService
    public let settings: SettingsService
    public let updater: UpdaterService
    public let vulnerabilities: VulnerabilitiesService
    public let ports: PortsService
    public let version: VersionService

    public init(configuration: Configuration) {
        self.configuration = configuration
        let authManager = AuthManager(
            baseURL: configuration.baseURL,
            tokenStore: configuration.tokenStore,
            apiKey: configuration.apiKey,
            urlSession: configuration.urlSession,
            decoder: configuration.jsonDecoder,
            encoder: configuration.jsonEncoder
        )
        self.authManager = authManager
        self.transport = ArcaneURLSessionTransport(
            baseURL: configuration.baseURL,
            session: configuration.urlSession,
            authManager: authManager,
            retryPolicy: configuration.retryPolicy,
            decoder: configuration.jsonDecoder,
            encoder: configuration.jsonEncoder
        )
        self.rest = RESTService(transport: transport, defaultEnvironmentID: configuration.defaultEnvironmentID)
        self.auth = AuthService(
            transport: transport,
            authManager: authManager,
            decoder: configuration.jsonDecoder,
            encoder: configuration.jsonEncoder
        )
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
        self.registries = ContainerRegistriesService(rest: rest)
        self.gitops = GitOpsService(rest: rest)
        self.builds = BuildsService(rest: rest)
        self.jobs = JobsService(rest: rest)
        self.settings = SettingsService(rest: rest)
        self.updater = UpdaterService(rest: rest)
        self.vulnerabilities = VulnerabilitiesService(rest: rest)
        self.ports = PortsService(rest: rest)
        self.version = VersionService(rest: rest)
    }

    public func scoped(toEnvironment envID: EnvironmentID) -> ArcaneClient {
        var scoped = configuration
        scoped.defaultEnvironmentID = envID
        return ArcaneClient(configuration: scoped)
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
    public static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: raw) {
                return date
            }
            let fallback = ISO8601DateFormatter()
            fallback.formatOptions = [.withInternetDateTime]
            if let date = fallback.date(from: raw) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date: \(raw)")
        }
        return decoder
    }

    public static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
