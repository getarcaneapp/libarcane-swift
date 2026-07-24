import Foundation

public enum PruneContainerMode: String, Codable, Hashable, Sendable {
  case none
  case stopped
  case olderThan
}

public enum PruneImageMode: String, Codable, Hashable, Sendable {
  case none
  case dangling
  case all
  case olderThan
}

public enum PruneVolumeMode: String, Codable, Hashable, Sendable {
  case none
  case anonymous
  case all
}

public enum PruneNetworkMode: String, Codable, Hashable, Sendable {
  case none
  case unused
  case olderThan
}

public enum PruneBuildCacheMode: String, Codable, Hashable, Sendable {
  case none
  case unused
  case all
  case olderThan
}

public struct PruneContainersOptions: Codable, Hashable, Sendable {
  public var mode: PruneContainerMode
  public var until: String?

  public init(mode: PruneContainerMode, until: String? = nil) {
    self.mode = mode
    self.until = until
  }
}

public struct PruneImagesOptions: Codable, Hashable, Sendable {
  public var mode: PruneImageMode
  public var until: String?

  public init(mode: PruneImageMode, until: String? = nil) {
    self.mode = mode
    self.until = until
  }
}

public struct PruneVolumesOptions: Codable, Hashable, Sendable {
  public var mode: PruneVolumeMode

  public init(mode: PruneVolumeMode) {
    self.mode = mode
  }
}

public struct PruneNetworksOptions: Codable, Hashable, Sendable {
  public var mode: PruneNetworkMode
  public var until: String?

  public init(mode: PruneNetworkMode, until: String? = nil) {
    self.mode = mode
    self.until = until
  }
}

public struct PruneBuildCacheOptions: Codable, Hashable, Sendable {
  public var mode: PruneBuildCacheMode
  public var until: String?

  public init(mode: PruneBuildCacheMode, until: String? = nil) {
    self.mode = mode
    self.until = until
  }
}

/// Body for `POST /environments/{id}/system/prune`.
public struct PruneAllRequest: Codable, Hashable, Sendable {
  public var containers: PruneContainersOptions?
  public var images: PruneImagesOptions?
  public var volumes: PruneVolumesOptions?
  public var networks: PruneNetworksOptions?
  public var buildCache: PruneBuildCacheOptions?

  public init(
    containers: PruneContainersOptions? = nil,
    images: PruneImagesOptions? = nil,
    volumes: PruneVolumesOptions? = nil,
    networks: PruneNetworksOptions? = nil,
    buildCache: PruneBuildCacheOptions? = nil
  ) {
    self.containers = containers
    self.images = images
    self.volumes = volumes
    self.networks = networks
    self.buildCache = buildCache
  }
}

/// Result of a system prune.
public struct PruneAllResult: Codable, Hashable, Sendable {
  public var containersPruned: [String]?
  public var imagesDeleted: [String]?
  public var volumesDeleted: [String]?
  public var networksDeleted: [String]?
  public var spaceReclaimed: UInt64
  public var containerSpaceReclaimed: UInt64?
  public var imageSpaceReclaimed: UInt64?
  public var volumeSpaceReclaimed: UInt64?
  public var buildCacheSpaceReclaimed: UInt64?
  public var success: Bool
  public var errors: [String]?
  public var activityID: String?

  public init(
    containersPruned: [String]? = nil,
    imagesDeleted: [String]? = nil,
    volumesDeleted: [String]? = nil,
    networksDeleted: [String]? = nil,
    spaceReclaimed: UInt64 = 0,
    containerSpaceReclaimed: UInt64? = nil,
    imageSpaceReclaimed: UInt64? = nil,
    volumeSpaceReclaimed: UInt64? = nil,
    buildCacheSpaceReclaimed: UInt64? = nil,
    success: Bool = false,
    errors: [String]? = nil,
    activityID: String? = nil
  ) {
    self.containersPruned = containersPruned
    self.imagesDeleted = imagesDeleted
    self.volumesDeleted = volumesDeleted
    self.networksDeleted = networksDeleted
    self.spaceReclaimed = spaceReclaimed
    self.containerSpaceReclaimed = containerSpaceReclaimed
    self.imageSpaceReclaimed = imageSpaceReclaimed
    self.volumeSpaceReclaimed = volumeSpaceReclaimed
    self.buildCacheSpaceReclaimed = buildCacheSpaceReclaimed
    self.success = success
    self.errors = errors
    self.activityID = activityID
  }

  private enum CodingKeys: String, CodingKey {
    case containersPruned, imagesDeleted, volumesDeleted, networksDeleted
    case spaceReclaimed, containerSpaceReclaimed, imageSpaceReclaimed
    case volumeSpaceReclaimed, buildCacheSpaceReclaimed, success, errors
    case activityID = "activityId"
  }
}
