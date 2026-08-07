import Foundation

/// One layer returned by Docker's image history endpoint.
public struct ImageHistoryItem: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var created: Int64
  public var createdBy: String
  public var tags: [String]
  public var size: Int64
  public var comment: String

  public init(
    id: String,
    created: Int64,
    createdBy: String,
    tags: [String] = [],
    size: Int64,
    comment: String = ""
  ) {
    self.id = id
    self.created = created
    self.createdBy = createdBy
    self.tags = tags
    self.size = size
    self.comment = comment
  }

  private enum CodingKeys: String, CodingKey {
    case id, created, createdBy, tags, size, comment
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decodeIfPresent(String.self, forKey: .id) ?? "<missing>"
    created = try container.decodeIfPresent(Int64.self, forKey: .created) ?? 0
    createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy) ?? ""
    tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    size = try container.decodeIfPresent(Int64.self, forKey: .size) ?? 0
    comment = try container.decodeIfPresent(String.self, forKey: .comment) ?? ""
  }
}
