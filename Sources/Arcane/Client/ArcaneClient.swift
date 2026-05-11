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
    public let auth: AuthService
    public let rest: RESTService
    public let containers: ContainersService
    public let images: ImagesService
    public let environments: EnvironmentsService
    public let system: SystemService
    public let projects: ProjectsService
    public let swarm: SwarmService
    public let updater: UpdaterService

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
        self.auth = AuthService(transport: transport, authManager: authManager)
        self.containers = ContainersService(rest: rest)
        self.images = ImagesService(rest: rest)
        self.environments = EnvironmentsService(rest: rest)
        self.system = SystemService(rest: rest)
        self.projects = ProjectsService(rest: rest)
        self.swarm = SwarmService(rest: rest)
        self.updater = UpdaterService(rest: rest)
    }

    public func scoped(toEnvironment envID: EnvironmentID) -> ArcaneClient {
        var scoped = configuration
        scoped.defaultEnvironmentID = envID
        return ArcaneClient(configuration: scoped)
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
