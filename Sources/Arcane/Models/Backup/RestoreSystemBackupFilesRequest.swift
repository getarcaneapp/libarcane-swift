import Foundation

public struct RestoreSystemBackupFilesRequest: Codable, Hashable, Sendable {
  public var paths: [String]?
  public var selectAll: Bool?
  public var search: String?
  public var recoveryKey: String

  public init(
    paths: [String]? = nil,
    selectAll: Bool? = nil,
    search: String? = nil,
    recoveryKey: String
  ) {
    self.paths = paths
    self.selectAll = selectAll
    self.search = search
    self.recoveryKey = recoveryKey
  }
}
