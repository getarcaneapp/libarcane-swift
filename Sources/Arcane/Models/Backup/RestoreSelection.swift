import Foundation

public struct RestoreSelection: Codable, Hashable, Sendable {
  public var paths: [String]?
  public var selectAll: Bool?
  public var search: String?

  public init(
    paths: [String]? = nil,
    selectAll: Bool? = nil,
    search: String? = nil
  ) {
    self.paths = paths
    self.selectAll = selectAll
    self.search = search
  }
}
