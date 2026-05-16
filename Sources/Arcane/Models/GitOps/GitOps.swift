import Foundation

public struct GitRepository: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var url: String
    public var authType: String
    public var username: String?
    public var sshHostKeyVerification: String?
    public var description: String?
    public var enabled: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String,
        name: String,
        url: String,
        authType: String,
        username: String? = nil,
        sshHostKeyVerification: String? = nil,
        description: String? = nil,
        enabled: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.authType = authType
        self.username = username
        self.sshHostKeyVerification = sshHostKeyVerification
        self.description = description
        self.enabled = enabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct CreateGitRepository: Codable, Hashable, Sendable {
    public var name: String
    public var url: String
    public var authType: String
    public var username: String?
    public var token: String?
    public var sshKey: String?
    public var sshHostKeyVerification: String?
    public var description: String?
    public var enabled: Bool?

    public init(
        name: String,
        url: String,
        authType: String,
        username: String? = nil,
        token: String? = nil,
        sshKey: String? = nil,
        sshHostKeyVerification: String? = nil,
        description: String? = nil,
        enabled: Bool? = nil
    ) {
        self.name = name
        self.url = url
        self.authType = authType
        self.username = username
        self.token = token
        self.sshKey = sshKey
        self.sshHostKeyVerification = sshHostKeyVerification
        self.description = description
        self.enabled = enabled
    }
}

public struct UpdateGitRepository: Codable, Hashable, Sendable {
    public var name: String?
    public var url: String?
    public var authType: String?
    public var username: String?
    public var token: String?
    public var sshKey: String?
    public var sshHostKeyVerification: String?
    public var description: String?
    public var enabled: Bool?

    public init(
        name: String? = nil,
        url: String? = nil,
        authType: String? = nil,
        username: String? = nil,
        token: String? = nil,
        sshKey: String? = nil,
        sshHostKeyVerification: String? = nil,
        description: String? = nil,
        enabled: Bool? = nil
    ) {
        self.name = name
        self.url = url
        self.authType = authType
        self.username = username
        self.token = token
        self.sshKey = sshKey
        self.sshHostKeyVerification = sshHostKeyVerification
        self.description = description
        self.enabled = enabled
    }
}

public struct GitOpsSync: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var environmentId: String
    public var repositoryId: String
    public var repository: GitRepository?
    public var branch: String
    public var composePath: String
    public var targetType: String
    public var projectName: String
    public var projectId: String?
    public var autoSync: Bool
    public var syncInterval: Int
    public var syncDirectory: Bool
    public var syncedFiles: String?
    public var maxSyncFiles: Int
    public var maxSyncTotalSize: Int64
    public var maxSyncBinarySize: Int64
    public var lastSyncAt: Date?
    public var lastSyncStatus: String?
    public var lastSyncError: String?
    public var lastSyncCommit: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String,
        name: String,
        environmentId: String,
        repositoryId: String,
        repository: GitRepository? = nil,
        branch: String,
        composePath: String,
        targetType: String,
        projectName: String,
        projectId: String? = nil,
        autoSync: Bool,
        syncInterval: Int,
        syncDirectory: Bool,
        syncedFiles: String? = nil,
        maxSyncFiles: Int,
        maxSyncTotalSize: Int64,
        maxSyncBinarySize: Int64,
        lastSyncAt: Date? = nil,
        lastSyncStatus: String? = nil,
        lastSyncError: String? = nil,
        lastSyncCommit: String? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.environmentId = environmentId
        self.repositoryId = repositoryId
        self.repository = repository
        self.branch = branch
        self.composePath = composePath
        self.targetType = targetType
        self.projectName = projectName
        self.projectId = projectId
        self.autoSync = autoSync
        self.syncInterval = syncInterval
        self.syncDirectory = syncDirectory
        self.syncedFiles = syncedFiles
        self.maxSyncFiles = maxSyncFiles
        self.maxSyncTotalSize = maxSyncTotalSize
        self.maxSyncBinarySize = maxSyncBinarySize
        self.lastSyncAt = lastSyncAt
        self.lastSyncStatus = lastSyncStatus
        self.lastSyncError = lastSyncError
        self.lastSyncCommit = lastSyncCommit
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct GitOpsSyncCounts: Codable, Hashable, Sendable {
    public var totalSyncs: Int
    public var activeSyncs: Int
    public var successfulSyncs: Int

    public init(totalSyncs: Int, activeSyncs: Int, successfulSyncs: Int) {
        self.totalSyncs = totalSyncs
        self.activeSyncs = activeSyncs
        self.successfulSyncs = successfulSyncs
    }
}

public struct CreateGitOpsSync: Codable, Hashable, Sendable {
    public var name: String
    public var repositoryId: String
    public var branch: String
    public var composePath: String
    public var targetType: String?
    public var projectName: String?
    public var autoSync: Bool?
    public var syncInterval: Int?
    public var syncDirectory: Bool?
    public var maxSyncFiles: Int?
    public var maxSyncTotalSize: Int64?
    public var maxSyncBinarySize: Int64?

    public init(
        name: String,
        repositoryId: String,
        branch: String,
        composePath: String,
        targetType: String? = nil,
        projectName: String? = nil,
        autoSync: Bool? = nil,
        syncInterval: Int? = nil,
        syncDirectory: Bool? = nil,
        maxSyncFiles: Int? = nil,
        maxSyncTotalSize: Int64? = nil,
        maxSyncBinarySize: Int64? = nil
    ) {
        self.name = name
        self.repositoryId = repositoryId
        self.branch = branch
        self.composePath = composePath
        self.targetType = targetType
        self.projectName = projectName
        self.autoSync = autoSync
        self.syncInterval = syncInterval
        self.syncDirectory = syncDirectory
        self.maxSyncFiles = maxSyncFiles
        self.maxSyncTotalSize = maxSyncTotalSize
        self.maxSyncBinarySize = maxSyncBinarySize
    }
}

public struct UpdateGitOpsSync: Codable, Hashable, Sendable {
    public var name: String?
    public var repositoryId: String?
    public var branch: String?
    public var composePath: String?
    public var targetType: String?
    public var projectName: String?
    public var autoSync: Bool?
    public var syncInterval: Int?
    public var syncDirectory: Bool?
    public var maxSyncFiles: Int?
    public var maxSyncTotalSize: Int64?
    public var maxSyncBinarySize: Int64?

    public init(
        name: String? = nil,
        repositoryId: String? = nil,
        branch: String? = nil,
        composePath: String? = nil,
        targetType: String? = nil,
        projectName: String? = nil,
        autoSync: Bool? = nil,
        syncInterval: Int? = nil,
        syncDirectory: Bool? = nil,
        maxSyncFiles: Int? = nil,
        maxSyncTotalSize: Int64? = nil,
        maxSyncBinarySize: Int64? = nil
    ) {
        self.name = name
        self.repositoryId = repositoryId
        self.branch = branch
        self.composePath = composePath
        self.targetType = targetType
        self.projectName = projectName
        self.autoSync = autoSync
        self.syncInterval = syncInterval
        self.syncDirectory = syncDirectory
        self.maxSyncFiles = maxSyncFiles
        self.maxSyncTotalSize = maxSyncTotalSize
        self.maxSyncBinarySize = maxSyncBinarySize
    }
}

public struct GitOpsSyncResult: Codable, Hashable, Sendable {
    public var success: Bool
    public var message: String
    public var error: String?
    public var syncedAt: Date

    public init(success: Bool, message: String, error: String? = nil, syncedAt: Date) {
        self.success = success
        self.message = message
        self.error = error
        self.syncedAt = syncedAt
    }
}

public enum GitOpsFileTreeNodeType: String, Codable, Hashable, Sendable {
    case file
    case directory
}

public struct GitOpsFileTreeNode: Codable, Hashable, Sendable {
    public var name: String
    public var path: String
    public var type: GitOpsFileTreeNodeType
    public var size: Int64?
    public var children: [GitOpsFileTreeNode]?

    public init(
        name: String,
        path: String,
        type: GitOpsFileTreeNodeType,
        size: Int64? = nil,
        children: [GitOpsFileTreeNode]? = nil
    ) {
        self.name = name
        self.path = path
        self.type = type
        self.size = size
        self.children = children
    }
}

public struct GitOpsBrowseResponse: Codable, Hashable, Sendable {
    public var path: String
    public var files: [GitOpsFileTreeNode]

    public init(path: String, files: [GitOpsFileTreeNode]) {
        self.path = path
        self.files = files
    }
}

public struct GitOpsBranchInfo: Codable, Hashable, Sendable {
    public var name: String
    public var isDefault: Bool

    public init(name: String, isDefault: Bool) {
        self.name = name
        self.isDefault = isDefault
    }
}

public struct GitOpsBranchesResponse: Codable, Hashable, Sendable {
    public var branches: [GitOpsBranchInfo]

    public init(branches: [GitOpsBranchInfo]) {
        self.branches = branches
    }
}

public struct GitOpsSyncStatus: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var autoSync: Bool
    public var nextSyncAt: Date?
    public var lastSyncAt: Date?
    public var lastSyncStatus: String?
    public var lastSyncError: String?
    public var lastSyncCommit: String?

    public init(
        id: String,
        autoSync: Bool,
        nextSyncAt: Date? = nil,
        lastSyncAt: Date? = nil,
        lastSyncStatus: String? = nil,
        lastSyncError: String? = nil,
        lastSyncCommit: String? = nil
    ) {
        self.id = id
        self.autoSync = autoSync
        self.nextSyncAt = nextSyncAt
        self.lastSyncAt = lastSyncAt
        self.lastSyncStatus = lastSyncStatus
        self.lastSyncError = lastSyncError
        self.lastSyncCommit = lastSyncCommit
    }
}

public struct GitRepositorySync: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var url: String
    public var authType: String
    public var username: String?
    public var token: String?
    public var sshKey: String?
    public var sshHostKeyVerification: String?
    public var description: String?
    public var enabled: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String,
        name: String,
        url: String,
        authType: String,
        username: String? = nil,
        token: String? = nil,
        sshKey: String? = nil,
        sshHostKeyVerification: String? = nil,
        description: String? = nil,
        enabled: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.authType = authType
        self.username = username
        self.token = token
        self.sshKey = sshKey
        self.sshHostKeyVerification = sshHostKeyVerification
        self.description = description
        self.enabled = enabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct GitRepositorySyncRequest: Codable, Hashable, Sendable {
    public var repositories: [GitRepositorySync]

    public init(repositories: [GitRepositorySync]) {
        self.repositories = repositories
    }
}

public struct ImportGitOpsSyncRequest: Codable, Hashable, Sendable {
    public var syncName: String
    public var gitRepo: String
    public var branch: String
    public var dockerComposePath: String
    public var autoSync: Bool
    public var syncInterval: Int
    public var syncDirectory: Bool?
    public var maxSyncFiles: Int?
    public var maxSyncTotalSize: Int64?
    public var maxSyncBinarySize: Int64?

    public init(
        syncName: String,
        gitRepo: String,
        branch: String,
        dockerComposePath: String,
        autoSync: Bool,
        syncInterval: Int,
        syncDirectory: Bool? = nil,
        maxSyncFiles: Int? = nil,
        maxSyncTotalSize: Int64? = nil,
        maxSyncBinarySize: Int64? = nil
    ) {
        self.syncName = syncName
        self.gitRepo = gitRepo
        self.branch = branch
        self.dockerComposePath = dockerComposePath
        self.autoSync = autoSync
        self.syncInterval = syncInterval
        self.syncDirectory = syncDirectory
        self.maxSyncFiles = maxSyncFiles
        self.maxSyncTotalSize = maxSyncTotalSize
        self.maxSyncBinarySize = maxSyncBinarySize
    }
}

public struct ImportGitOpsSyncResponse: Codable, Hashable, Sendable {
    public var successCount: Int
    public var failedCount: Int
    public var errors: [String]

    public init(successCount: Int, failedCount: Int, errors: [String]) {
        self.successCount = successCount
        self.failedCount = failedCount
        self.errors = errors
    }
}
