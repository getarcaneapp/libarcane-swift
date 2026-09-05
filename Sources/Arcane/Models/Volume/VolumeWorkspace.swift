import Foundation

/// Volume and project workspaces share the server's workspace response contract.
public typealias VolumeWorkspace = ProjectWorkspace
public typealias VolumeWorkspaceFileContent = ProjectWorkspaceFileContent

public enum VolumeWorkspaceOperation: String, Codable, Hashable, Sendable {
  case createFile = "create_file"
  case createFolder = "create_folder"
  case updateFile = "update_file"
  case rename, move, delete
  case restoreFile = "restore_file"
}

/// Upload indices refer to the ordered file URLs passed to `updateWorkspace`.
public struct VolumeWorkspaceFileChange: Codable, Hashable, Sendable {
  public var operation: VolumeWorkspaceOperation
  public var relativePath: String
  public var newName: String?
  public var newParentPath: String?
  public var uploadIndex: Int?
  public var baselineIndex: Int?
  public var backupId: String?
  public var recursive: Bool?

  public init(
    operation: VolumeWorkspaceOperation, relativePath: String,
    newName: String? = nil, newParentPath: String? = nil, uploadIndex: Int? = nil,
    baselineIndex: Int? = nil, backupId: String? = nil, recursive: Bool? = nil
  ) {
    self.operation = operation
    self.relativePath = relativePath
    self.newName = newName
    self.newParentPath = newParentPath
    self.uploadIndex = uploadIndex
    self.baselineIndex = baselineIndex
    self.backupId = backupId
    self.recursive = recursive
  }
}

public struct VolumeWorkspaceUpdateManifest: Codable, Hashable, Sendable {
  public var fileTreeRevision: String
  public var fileChanges: [VolumeWorkspaceFileChange]

  public init(fileTreeRevision: String, fileChanges: [VolumeWorkspaceFileChange]) {
    self.fileTreeRevision = fileTreeRevision
    self.fileChanges = fileChanges
  }
}
