import Foundation

/// Describes the project, container, or other consumer using an image.
public struct ImageUsedBy: Codable, Hashable, Sendable {
  public var type: String
  public var name: String
  public var id: String?

  public init(type: String, name: String, id: String? = nil) {
    self.type = type
    self.name = name
    self.id = id
  }
}

/// Image summary as returned by the list endpoint.
public struct ImageSummary: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var repoTags: [String]
  public var repoDigests: [String]
  public var created: Int64
  public var size: Int64
  public var virtualSize: Int64
  public var labels: [String: JSONValue]
  public var inUse: Bool
  public var usedBy: [ImageUsedBy]?
  public var repo: String
  public var tag: String
  public var updateInfo: ImageUpdateInfo?
  public var vulnerabilityScan: VulnerabilityScanSummary?

  private enum CodingKeys: String, CodingKey {
    case id
    case repoTags
    case repoDigests
    case created
    case size
    case virtualSize
    case labels
    case inUse
    case usedBy
    case repo
    case tag
    case updateInfo
    case vulnerabilityScan
  }

  public init(
    id: String,
    repoTags: [String] = [],
    repoDigests: [String] = [],
    created: Int64 = 0,
    size: Int64 = 0,
    virtualSize: Int64 = 0,
    labels: [String: JSONValue] = [:],
    inUse: Bool = false,
    usedBy: [ImageUsedBy]? = nil,
    repo: String = "",
    tag: String = "",
    updateInfo: ImageUpdateInfo? = nil,
    vulnerabilityScan: VulnerabilityScanSummary? = nil
  ) {
    self.id = id
    self.repoTags = repoTags
    self.repoDigests = repoDigests
    self.created = created
    self.size = size
    self.virtualSize = virtualSize
    self.labels = labels
    self.inUse = inUse
    self.usedBy = usedBy
    self.repo = repo
    self.tag = tag
    self.updateInfo = updateInfo
    self.vulnerabilityScan = vulnerabilityScan
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    repoTags = try container.decode([String].self, forKey: .repoTags)
    repoDigests = try container.decode([String].self, forKey: .repoDigests)
    created = try container.decode(Int64.self, forKey: .created)
    size = try container.decode(Int64.self, forKey: .size)
    virtualSize = try container.decode(Int64.self, forKey: .virtualSize)
    labels = try container.decodeEmptyDictionaryIfPresent([String: JSONValue].self, forKey: .labels)
    inUse = try container.decode(Bool.self, forKey: .inUse)
    usedBy = try container.decodeIfPresent([ImageUsedBy].self, forKey: .usedBy)
    repo = try container.decode(String.self, forKey: .repo)
    tag = try container.decode(String.self, forKey: .tag)
    updateInfo = try container.decodeIfPresent(ImageUpdateInfo.self, forKey: .updateInfo)
    vulnerabilityScan = try container.decodeIfPresent(
      VulnerabilityScanSummary.self, forKey: .vulnerabilityScan)
  }
}

/// Result of an image prune operation.
public struct ImagePruneReport: Codable, Hashable, Sendable {
  public var imagesDeleted: [String]
  public var spaceReclaimed: Int64

  public init(imagesDeleted: [String] = [], spaceReclaimed: Int64 = 0) {
    self.imagesDeleted = imagesDeleted
    self.spaceReclaimed = spaceReclaimed
  }
}

/// Aggregate image usage counts for an environment.
public struct ImageUsageCounts: Codable, Hashable, Sendable {
  public var imagesInuse: Int
  public var imagesUnused: Int
  public var totalImages: Int
  public var totalImageSize: Int64

  public init(
    imagesInuse: Int = 0,
    imagesUnused: Int = 0,
    totalImages: Int = 0,
    totalImageSize: Int64 = 0
  ) {
    self.imagesInuse = imagesInuse
    self.imagesUnused = imagesUnused
    self.totalImages = totalImages
    self.totalImageSize = totalImageSize
  }
}

/// Result of a `docker load` operation.
public struct ImageLoadResult: Codable, Hashable, Sendable {
  public var stream: String

  public init(stream: String = "") {
    self.stream = stream
  }
}

/// Paginated list response for images.
public struct ImageListResponse: Decodable, Sendable {
  public var success: Bool
  public var data: [ImageSummary]
  public var pagination: PaginationResponse
}
