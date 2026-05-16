import Foundation

/// Options for building an image with BuildKit.
public struct ImageBuildRequest: Codable, Hashable, Sendable {
    public var contextDir: String
    public var dockerfile: String?
    public var dockerfileInline: String?
    public var tags: [String]?
    public var target: String?
    public var buildArgs: [String: String]?
    public var labels: [String: String]?
    public var cacheFrom: [String]?
    public var cacheTo: [String]?
    public var noCache: Bool?
    public var pull: Bool?
    public var network: String?
    public var isolation: String?
    public var shmSize: Int64?
    public var ulimits: [String: String]?
    public var entitlements: [String]?
    public var privileged: Bool?
    public var extraHosts: [String]?
    public var platforms: [String]?
    public var push: Bool?
    public var load: Bool?
    public var provider: String?

    public init(
        contextDir: String,
        dockerfile: String? = nil,
        dockerfileInline: String? = nil,
        tags: [String]? = nil,
        target: String? = nil,
        buildArgs: [String: String]? = nil,
        labels: [String: String]? = nil,
        cacheFrom: [String]? = nil,
        cacheTo: [String]? = nil,
        noCache: Bool? = nil,
        pull: Bool? = nil,
        network: String? = nil,
        isolation: String? = nil,
        shmSize: Int64? = nil,
        ulimits: [String: String]? = nil,
        entitlements: [String]? = nil,
        privileged: Bool? = nil,
        extraHosts: [String]? = nil,
        platforms: [String]? = nil,
        push: Bool? = nil,
        load: Bool? = nil,
        provider: String? = nil
    ) {
        self.contextDir = contextDir
        self.dockerfile = dockerfile
        self.dockerfileInline = dockerfileInline
        self.tags = tags
        self.target = target
        self.buildArgs = buildArgs
        self.labels = labels
        self.cacheFrom = cacheFrom
        self.cacheTo = cacheTo
        self.noCache = noCache
        self.pull = pull
        self.network = network
        self.isolation = isolation
        self.shmSize = shmSize
        self.ulimits = ulimits
        self.entitlements = entitlements
        self.privileged = privileged
        self.extraHosts = extraHosts
        self.platforms = platforms
        self.push = push
        self.load = load
        self.provider = provider
    }
}

/// Result of an image build.
public struct ImageBuildResult: Codable, Hashable, Sendable {
    public var provider: String
    public var tags: [String]?
    public var digest: String?

    public init(provider: String = "", tags: [String]? = nil, digest: String? = nil) {
        self.provider = provider
        self.tags = tags
        self.digest = digest
    }
}

/// A historical image build entry.
public struct ImageBuildRecord: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var environmentId: String
    public var userId: String?
    public var username: String?
    public var status: String
    public var provider: String?
    public var contextDir: String
    public var dockerfile: String?
    public var target: String?
    public var tags: [String]?
    public var platforms: [String]?
    public var buildArgs: [String: String]?
    public var labels: [String: String]?
    public var cacheFrom: [String]?
    public var cacheTo: [String]?
    public var noCache: Bool
    public var pull: Bool
    public var network: String?
    public var isolation: String?
    public var shmSize: Int64?
    public var ulimits: [String: String]?
    public var entitlements: [String]?
    public var privileged: Bool
    public var extraHosts: [String]?
    public var push: Bool
    public var load: Bool
    public var digest: String?
    public var errorMessage: String?
    public var output: String?
    public var outputTruncated: Bool
    public var completedAt: Date?
    public var durationMs: Int64?
    public var createdAt: Date

    public init(
        id: String,
        environmentId: String,
        userId: String? = nil,
        username: String? = nil,
        status: String,
        provider: String? = nil,
        contextDir: String,
        dockerfile: String? = nil,
        target: String? = nil,
        tags: [String]? = nil,
        platforms: [String]? = nil,
        buildArgs: [String: String]? = nil,
        labels: [String: String]? = nil,
        cacheFrom: [String]? = nil,
        cacheTo: [String]? = nil,
        noCache: Bool = false,
        pull: Bool = false,
        network: String? = nil,
        isolation: String? = nil,
        shmSize: Int64? = nil,
        ulimits: [String: String]? = nil,
        entitlements: [String]? = nil,
        privileged: Bool = false,
        extraHosts: [String]? = nil,
        push: Bool = false,
        load: Bool = false,
        digest: String? = nil,
        errorMessage: String? = nil,
        output: String? = nil,
        outputTruncated: Bool = false,
        completedAt: Date? = nil,
        durationMs: Int64? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.environmentId = environmentId
        self.userId = userId
        self.username = username
        self.status = status
        self.provider = provider
        self.contextDir = contextDir
        self.dockerfile = dockerfile
        self.target = target
        self.tags = tags
        self.platforms = platforms
        self.buildArgs = buildArgs
        self.labels = labels
        self.cacheFrom = cacheFrom
        self.cacheTo = cacheTo
        self.noCache = noCache
        self.pull = pull
        self.network = network
        self.isolation = isolation
        self.shmSize = shmSize
        self.ulimits = ulimits
        self.entitlements = entitlements
        self.privileged = privileged
        self.extraHosts = extraHosts
        self.push = push
        self.load = load
        self.digest = digest
        self.errorMessage = errorMessage
        self.output = output
        self.outputTruncated = outputTruncated
        self.completedAt = completedAt
        self.durationMs = durationMs
        self.createdAt = createdAt
    }
}
