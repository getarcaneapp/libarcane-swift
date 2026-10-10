import Foundation

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

// MARK: - Git backup mode

public struct GitBackupFileChange: Codable, Hashable, Sendable {
  public var path: String
  public var change: String

  public init(path: String, change: String) {
    self.path = path
    self.change = change
  }
}

public struct GitBackupPreview: Codable, Hashable, Sendable {
  public var state: String
  public var remoteCommit: String?
  public var changes: [GitBackupFileChange]
  public var conflicts: [GitBackupFileChange]
  public var files: [String]

  public init(
    state: String,
    remoteCommit: String? = nil,
    changes: [GitBackupFileChange] = [],
    conflicts: [GitBackupFileChange] = [],
    files: [String] = []
  ) {
    self.state = state
    self.remoteCommit = remoteCommit
    self.changes = changes
    self.conflicts = conflicts
    self.files = files
  }
}

public struct GitBackupHistoryEntry: Codable, Hashable, Sendable {
  public var commit: String
  public var author: String
  public var message: String
  public var date: Date
  public var files: [String]

  public init(commit: String, author: String, message: String, date: Date, files: [String] = []) {
    self.commit = commit
    self.author = author
    self.message = message
    self.date = date
    self.files = files
  }
}

public struct GitBackupHistoryResponse: Codable, Hashable, Sendable {
  public var entries: [GitBackupHistoryEntry]

  public init(entries: [GitBackupHistoryEntry] = []) {
    self.entries = entries
  }
}

public struct GitBackupFileDiff: Codable, Hashable, Sendable {
  public var path: String
  public var patch: String

  public init(path: String, patch: String) {
    self.path = path
    self.patch = patch
  }
}

public struct GitBackupRevision: Codable, Hashable, Sendable {
  public var entry: GitBackupHistoryEntry
  public var diffs: [GitBackupFileDiff]

  public init(entry: GitBackupHistoryEntry, diffs: [GitBackupFileDiff] = []) {
    self.entry = entry
    self.diffs = diffs
  }
}

public struct ResolveGitBackupConflictRequest: Codable, Hashable, Sendable {
  public var strategy: String

  public init(strategy: String = "use_arcane") {
    self.strategy = strategy
  }
}
