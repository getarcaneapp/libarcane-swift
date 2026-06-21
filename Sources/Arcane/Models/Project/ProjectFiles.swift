import Foundation

/// ProjectFile represents an editable file or folder within a project directory.
public struct ProjectFile: Codable, Hashable, Sendable {
    public var path: String
    public var relativePath: String
    public var name: String
    public var isDirectory: Bool
    public var size: Int64
    public var modTime: Date?
    public var protected: Bool?
    public var content: String?

    public init(
        path: String,
        relativePath: String,
        name: String,
        isDirectory: Bool,
        size: Int64 = 0,
        modTime: Date? = nil,
        protected: Bool? = nil,
        content: String? = nil
    ) {
        self.path = path
        self.relativePath = relativePath
        self.name = name
        self.isDirectory = isDirectory
        self.size = size
        self.modTime = modTime
        self.protected = protected
        self.content = content
    }
}

/// ProjectFileDraft is staged when creating a project with custom files.
public struct ProjectFileDraft: Codable, Hashable, Sendable {
    public var relativePath: String
    public var isDirectory: Bool
    public var content: String?

    public init(relativePath: String, isDirectory: Bool = false, content: String? = nil) {
        self.relativePath = relativePath
        self.isDirectory = isDirectory
        self.content = content
    }
}

/// Operations accepted by Arcane's project file management API.
public enum ProjectFileChangeOperation: String, Codable, Hashable, Sendable {
    case createFile = "create_file"
    case createFolder = "create_folder"
    case updateFile = "update_file"
    case rename
    case move
    case delete
}

/// ProjectFileChange describes one staged file-tree operation for project update.
public struct ProjectFileChange: Codable, Hashable, Sendable {
    public var operation: ProjectFileChangeOperation
    public var relativePath: String
    public var newName: String?
    public var newParentPath: String?
    public var content: String?
    public var recursive: Bool?

    public init(
        operation: ProjectFileChangeOperation,
        relativePath: String,
        newName: String? = nil,
        newParentPath: String? = nil,
        content: String? = nil,
        recursive: Bool? = nil
    ) {
        self.operation = operation
        self.relativePath = relativePath
        self.newName = newName
        self.newParentPath = newParentPath
        self.content = content
        self.recursive = recursive
    }
}
