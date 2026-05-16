import Foundation

/// BackupEntry represents a single volume backup record.
public struct BackupEntry: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var volumeName: String
    public var size: Int64
    public var createdAt: String

    public init(id: String, volumeName: String, size: Int64, createdAt: String) {
        self.id = id
        self.volumeName = volumeName
        self.size = size
        self.createdAt = createdAt
    }
}

/// VolumeBackupListPage is the page envelope returned by ``GET volumes/{name}/backups``.
public struct VolumeBackupListPage: Decodable, Sendable {
    public var success: Bool
    public var data: [BackupEntry]
    public var pagination: PaginationResponse
    public var warnings: [String]?
}

/// BackupHasPath is the response for the ``has-path`` lookup.
public struct BackupHasPath: Codable, Hashable, Sendable {
    public var exists: Bool

    public init(exists: Bool) {
        self.exists = exists
    }
}

/// RestoreBackupFilesRequest is the body for the partial restore endpoint.
public struct RestoreBackupFilesRequest: Codable, Hashable, Sendable {
    public var paths: [String]

    public init(paths: [String]) {
        self.paths = paths
    }
}
