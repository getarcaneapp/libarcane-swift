import Foundation

public struct BackupFileEntry: Codable, Hashable, Sendable {
  public var path: String
  public var name: String
  public var isDirectory: Bool

  public init(
    path: String,
    name: String,
    isDirectory: Bool
  ) {
    self.path = path
    self.name = name
    self.isDirectory = isDirectory
  }
}
