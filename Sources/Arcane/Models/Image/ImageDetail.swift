import Foundation

/// The `config` block on an `ImageDetailSummary`.
public struct ImageDetailConfig: Codable, Hashable, Sendable {
    public var exposedPorts: [String: JSONValue]?
    public var env: [String]?
    public var cmd: [String]?
    public var entrypoint: [String]?
    public var user: String?
    public var volumes: [String: JSONValue]?
    public var workingDir: String?
    public var argsEscaped: Bool?
    public var labels: [String: String]?

    public init(
        exposedPorts: [String: JSONValue]? = nil,
        env: [String]? = nil,
        cmd: [String]? = nil,
        entrypoint: [String]? = nil,
        user: String? = nil,
        volumes: [String: JSONValue]? = nil,
        workingDir: String? = nil,
        argsEscaped: Bool? = nil,
        labels: [String: String]? = nil
    ) {
        self.exposedPorts = exposedPorts
        self.env = env
        self.cmd = cmd
        self.entrypoint = entrypoint
        self.user = user
        self.volumes = volumes
        self.workingDir = workingDir
        self.argsEscaped = argsEscaped
        self.labels = labels
    }
}

/// The `graphDriver` block on an `ImageDetailSummary`.
public struct ImageDetailGraphDriver: Codable, Hashable, Sendable {
    public var data: JSONValue?
    public var name: String

    public init(data: JSONValue? = nil, name: String = "") {
        self.data = data
        self.name = name
    }
}

/// The `rootFs` block on an `ImageDetailSummary`.
public struct ImageDetailRootFs: Codable, Hashable, Sendable {
    public var type: String
    public var layers: [String]

    public init(type: String = "", layers: [String] = []) {
        self.type = type
        self.layers = layers
    }
}

/// The `metadata` block on an `ImageDetailSummary`.
public struct ImageDetailMetadata: Codable, Hashable, Sendable {
    public var lastTagTime: String

    public init(lastTagTime: String = "") {
        self.lastTagTime = lastTagTime
    }
}

/// The `descriptor` block on an `ImageDetailSummary`.
public struct ImageDetailDescriptor: Codable, Hashable, Sendable {
    public var mediaType: String
    public var digest: String
    public var size: Int64

    public init(mediaType: String = "", digest: String = "", size: Int64 = 0) {
        self.mediaType = mediaType
        self.digest = digest
        self.size = size
    }
}

/// Detailed information about a single image (the `inspect` response shape).
public struct ImageDetailSummary: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var repoTags: [String]
    public var repoDigests: [String]
    public var comment: String
    public var created: String
    public var author: String
    public var config: ImageDetailConfig
    public var architecture: String
    public var os: String
    public var size: Int64
    public var graphDriver: ImageDetailGraphDriver
    public var rootFs: ImageDetailRootFs
    public var metadata: ImageDetailMetadata
    public var descriptor: ImageDetailDescriptor

    public init(
        id: String = "",
        repoTags: [String] = [],
        repoDigests: [String] = [],
        comment: String = "",
        created: String = "",
        author: String = "",
        config: ImageDetailConfig = .init(),
        architecture: String = "",
        os: String = "",
        size: Int64 = 0,
        graphDriver: ImageDetailGraphDriver = .init(),
        rootFs: ImageDetailRootFs = .init(),
        metadata: ImageDetailMetadata = .init(),
        descriptor: ImageDetailDescriptor = .init()
    ) {
        self.id = id
        self.repoTags = repoTags
        self.repoDigests = repoDigests
        self.comment = comment
        self.created = created
        self.author = author
        self.config = config
        self.architecture = architecture
        self.os = os
        self.size = size
        self.graphDriver = graphDriver
        self.rootFs = rootFs
        self.metadata = metadata
        self.descriptor = descriptor
    }
}
