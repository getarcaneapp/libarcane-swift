import Foundation

/// IncludeFile represents a project-related file (compose include, env file, or
/// other on-disk file shown in the project view).
public struct IncludeFile: Codable, Hashable, Sendable {
    public var path: String
    public var relativePath: String
    public var content: String?

    public init(path: String, relativePath: String, content: String? = nil) {
        self.path = path
        self.relativePath = relativePath
        self.content = content
    }
}

/// CreateProject is the body for ``POST /environments/{id}/projects``.
public struct CreateProject: Codable, Hashable, Sendable {
    public var name: String
    public var composeContent: String
    public var envContent: String?

    public init(name: String, composeContent: String, envContent: String? = nil) {
        self.name = name
        self.composeContent = composeContent
        self.envContent = envContent
    }
}

/// UpdateProject is the body for ``PUT /environments/{id}/projects/{id}``.
public struct UpdateProject: Codable, Hashable, Sendable {
    public var name: String?
    public var composeContent: String?
    public var envContent: String?

    public init(
        name: String? = nil,
        composeContent: String? = nil,
        envContent: String? = nil
    ) {
        self.name = name
        self.composeContent = composeContent
        self.envContent = envContent
    }
}

/// DeployOptions configures the deploy/up call.
public struct DeployOptions: Codable, Hashable, Sendable {
    public var pullPolicy: String?
    public var forceRecreate: Bool?

    public init(pullPolicy: String? = nil, forceRecreate: Bool? = nil) {
        self.pullPolicy = pullPolicy
        self.forceRecreate = forceRecreate
    }
}

/// UpdateIncludeFile is the body for the include file update endpoint.
public struct UpdateIncludeFile: Codable, Hashable, Sendable {
    public var relativePath: String
    public var content: String

    public init(relativePath: String, content: String) {
        self.relativePath = relativePath
        self.content = content
    }
}

/// RuntimeService contains live container state for one compose service.
public struct RuntimeService: Codable, Hashable, Sendable {
    public var name: String
    public var image: String
    public var status: String
    public var containerId: String?
    public var containerName: String?
    public var ports: [String]?
    public var health: String?
    public var iconUrl: String?
    public var serviceConfig: [String: JSONValue]?
    public var redeployDisabled: Bool?

    public init(
        name: String,
        image: String,
        status: String,
        containerId: String? = nil,
        containerName: String? = nil,
        ports: [String]? = nil,
        health: String? = nil,
        iconUrl: String? = nil,
        serviceConfig: [String: JSONValue]? = nil,
        redeployDisabled: Bool? = nil
    ) {
        self.name = name
        self.image = image
        self.status = status
        self.containerId = containerId
        self.containerName = containerName
        self.ports = ports
        self.health = health
        self.iconUrl = iconUrl
        self.serviceConfig = serviceConfig
        self.redeployDisabled = redeployDisabled
    }
}

/// ProjectUpdateInfo summarises image update status for the whole project.
public struct ProjectUpdateInfo: Codable, Hashable, Sendable {
    public var status: String
    public var hasUpdate: Bool
    public var imageCount: Int
    public var checkedImageCount: Int
    public var imagesWithUpdates: Int
    public var errorCount: Int
    public var errorMessage: String?
    public var imageRefs: [String]?
    public var updatedImageRefs: [String]?
    public var lastCheckedAt: Date?

    public init(
        status: String,
        hasUpdate: Bool,
        imageCount: Int,
        checkedImageCount: Int,
        imagesWithUpdates: Int,
        errorCount: Int,
        errorMessage: String? = nil,
        imageRefs: [String]? = nil,
        updatedImageRefs: [String]? = nil,
        lastCheckedAt: Date? = nil
    ) {
        self.status = status
        self.hasUpdate = hasUpdate
        self.imageCount = imageCount
        self.checkedImageCount = checkedImageCount
        self.imagesWithUpdates = imagesWithUpdates
        self.errorCount = errorCount
        self.errorMessage = errorMessage
        self.imageRefs = imageRefs
        self.updatedImageRefs = updatedImageRefs
        self.lastCheckedAt = lastCheckedAt
    }
}

/// ProjectCreateResponse is the response for ``POST projects``.
public struct ProjectCreateResponse: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var dirName: String?
    public var relativePath: String?
    public var path: String
    public var status: String
    public var statusReason: String?
    public var serviceCount: Int
    public var runningCount: Int
    public var gitOpsManagedBy: String?
    public var isArchived: Bool
    public var archivedAt: Date?
    public var createdAt: String
    public var updatedAt: String

    public init(
        id: String,
        name: String,
        dirName: String? = nil,
        relativePath: String? = nil,
        path: String,
        status: String,
        statusReason: String? = nil,
        serviceCount: Int = 0,
        runningCount: Int = 0,
        gitOpsManagedBy: String? = nil,
        isArchived: Bool = false,
        archivedAt: Date? = nil,
        createdAt: String,
        updatedAt: String
    ) {
        self.id = id
        self.name = name
        self.dirName = dirName
        self.relativePath = relativePath
        self.path = path
        self.status = status
        self.statusReason = statusReason
        self.serviceCount = serviceCount
        self.runningCount = runningCount
        self.gitOpsManagedBy = gitOpsManagedBy
        self.isArchived = isArchived
        self.archivedAt = archivedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// ProjectDetails is the full project view returned by the list/details endpoints.
public struct ProjectDetails: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var dirName: String?
    public var relativePath: String?
    public var path: String
    public var iconUrl: String?
    public var urls: [String]?
    public var composeContent: String?
    public var composeFileName: String?
    public var envContent: String?
    public var includeFiles: [IncludeFile]?
    public var directoryFiles: [IncludeFile]?
    public var status: String
    public var statusReason: String?
    public var serviceCount: Int
    public var runningCount: Int
    public var isArchived: Bool
    public var isDiscovered: Bool?
    public var archivedAt: Date?
    public var createdAt: String
    public var updatedAt: String
    public var services: [[String: JSONValue]]?
    public var runtimeServices: [RuntimeService]?
    public var updateInfo: ProjectUpdateInfo?
    public var hasBuildDirective: Bool?
    public var redeployDisabled: Bool?
    public var gitOpsManagedBy: String?
    public var lastSyncCommit: String?
    public var gitRepositoryURL: String?

    public init(
        id: String,
        name: String,
        dirName: String? = nil,
        relativePath: String? = nil,
        path: String,
        iconUrl: String? = nil,
        urls: [String]? = nil,
        composeContent: String? = nil,
        composeFileName: String? = nil,
        envContent: String? = nil,
        includeFiles: [IncludeFile]? = nil,
        directoryFiles: [IncludeFile]? = nil,
        status: String,
        statusReason: String? = nil,
        serviceCount: Int = 0,
        runningCount: Int = 0,
        isArchived: Bool = false,
        isDiscovered: Bool? = nil,
        archivedAt: Date? = nil,
        createdAt: String,
        updatedAt: String,
        services: [[String: JSONValue]]? = nil,
        runtimeServices: [RuntimeService]? = nil,
        updateInfo: ProjectUpdateInfo? = nil,
        hasBuildDirective: Bool? = nil,
        redeployDisabled: Bool? = nil,
        gitOpsManagedBy: String? = nil,
        lastSyncCommit: String? = nil,
        gitRepositoryURL: String? = nil
    ) {
        self.id = id
        self.name = name
        self.dirName = dirName
        self.relativePath = relativePath
        self.path = path
        self.iconUrl = iconUrl
        self.urls = urls
        self.composeContent = composeContent
        self.composeFileName = composeFileName
        self.envContent = envContent
        self.includeFiles = includeFiles
        self.directoryFiles = directoryFiles
        self.status = status
        self.statusReason = statusReason
        self.serviceCount = serviceCount
        self.runningCount = runningCount
        self.isArchived = isArchived
        self.isDiscovered = isDiscovered
        self.archivedAt = archivedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.services = services
        self.runtimeServices = runtimeServices
        self.updateInfo = updateInfo
        self.hasBuildDirective = hasBuildDirective
        self.redeployDisabled = redeployDisabled
        self.gitOpsManagedBy = gitOpsManagedBy
        self.lastSyncCommit = lastSyncCommit
        self.gitRepositoryURL = gitRepositoryURL
    }
}

/// DestroyProject is the body for the destroy endpoint.
public struct DestroyProject: Codable, Hashable, Sendable {
    public var removeFiles: Bool?
    public var removeVolumes: Bool?

    public init(removeFiles: Bool? = nil, removeVolumes: Bool? = nil) {
        self.removeFiles = removeFiles
        self.removeVolumes = removeVolumes
    }
}

/// ProjectStatusCounts summarises project status counts for an environment.
public struct ProjectStatusCounts: Codable, Hashable, Sendable {
    public var runningProjects: Int
    public var stoppedProjects: Int
    public var totalProjects: Int
    public var archivedProjects: Int

    public init(
        runningProjects: Int = 0,
        stoppedProjects: Int = 0,
        totalProjects: Int = 0,
        archivedProjects: Int = 0
    ) {
        self.runningProjects = runningProjects
        self.stoppedProjects = stoppedProjects
        self.totalProjects = totalProjects
        self.archivedProjects = archivedProjects
    }
}

/// ImagePullRequest is the body for ``POST projects/{id}/pull``.
public struct ImagePullRequest: Codable, Hashable, Sendable {
    public var credentials: [ContainerRegistryCredential]?

    public init(credentials: [ContainerRegistryCredential]? = nil) {
        self.credentials = credentials
    }
}

/// BuildProjectRequest is the body for ``POST projects/{id}/build``.
public struct BuildProjectRequest: Codable, Hashable, Sendable {
    public var services: [String]?
    public var provider: String?
    public var push: Bool?
    public var load: Bool?

    public init(
        services: [String]? = nil,
        provider: String? = nil,
        push: Bool? = nil,
        load: Bool? = nil
    ) {
        self.services = services
        self.provider = provider
        self.push = push
        self.load = load
    }
}

/// PullProgressEvent is one frame of the streaming pull progress.
public struct PullProgressEvent: Codable, Hashable, Sendable {
    public struct Detail: Codable, Hashable, Sendable {
        public var current: Int64?
        public var total: Int64?

        public init(current: Int64? = nil, total: Int64? = nil) {
            self.current = current
            self.total = total
        }
    }

    public var status: String?
    public var id: String?
    public var progress: String?
    public var progressDetail: Detail?
    public var error: String?

    public init(
        status: String? = nil,
        id: String? = nil,
        progress: String? = nil,
        progressDetail: Detail? = nil,
        error: String? = nil
    ) {
        self.status = status
        self.id = id
        self.progress = progress
        self.progressDetail = progressDetail
        self.error = error
    }
}

/// ProjectListPage is the page envelope for ``GET /environments/{id}/projects``.
public struct ProjectListPage: Decodable, Sendable {
    public var success: Bool
    public var data: [ProjectDetails]
    public var pagination: PaginationResponse
}
