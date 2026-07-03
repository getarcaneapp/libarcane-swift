import Foundation

/// Resource statistics for a single GPU.
public struct GPUStats: Codable, Hashable, Sendable {
  public var name: String
  public var index: Int
  public var memoryUsed: Double
  public var memoryTotal: Double

  public init(name: String, index: Int, memoryUsed: Double, memoryTotal: Double) {
    self.name = name
    self.index = index
    self.memoryUsed = memoryUsed
    self.memoryTotal = memoryTotal
  }
}

/// System resource statistics for WebSocket streaming over
/// `/environments/{id}/ws/system/stats`.
public struct SystemStats: Codable, Hashable, Sendable {
  public var cpuUsage: Double
  public var memoryUsage: UInt64
  public var memoryTotal: UInt64
  public var diskUsage: UInt64?
  public var diskTotal: UInt64?
  public var cpuCount: Int
  public var architecture: String
  public var platform: String
  public var hostname: String?
  public var gpuCount: Int
  public var gpus: [GPUStats]?

  public init(
    cpuUsage: Double,
    memoryUsage: UInt64,
    memoryTotal: UInt64,
    diskUsage: UInt64? = nil,
    diskTotal: UInt64? = nil,
    cpuCount: Int,
    architecture: String,
    platform: String,
    hostname: String? = nil,
    gpuCount: Int,
    gpus: [GPUStats]? = nil
  ) {
    self.cpuUsage = cpuUsage
    self.memoryUsage = memoryUsage
    self.memoryTotal = memoryTotal
    self.diskUsage = diskUsage
    self.diskTotal = diskTotal
    self.cpuCount = cpuCount
    self.architecture = architecture
    self.platform = platform
    self.hostname = hostname
    self.gpuCount = gpuCount
    self.gpus = gpus
  }
}
