import Foundation

/// Compact history sample for container CPU and memory usage.
public struct ContainerStatsHistorySample: Codable, Hashable, Sendable {
  public var cpuTenths: UInt16
  public var memoryTenths: UInt16
  public var memoryUsageBytes: UInt64

  public init(cpuTenths: UInt16 = 0, memoryTenths: UInt16 = 0, memoryUsageBytes: UInt64 = 0) {
    self.cpuTenths = cpuTenths
    self.memoryTenths = memoryTenths
    self.memoryUsageBytes = memoryUsageBytes
  }
}

/// Container stats websocket payload. Mirrors Docker's StatsResponse (embedded)
/// plus Arcane-added history. The Docker portion is exposed as raw JSON so we
/// stay forward-compatible with the upstream schema.
public struct ContainerStatsPayload: Codable, Hashable, Sendable {
  /// Raw Docker stats fields (anything not under `statsHistory` / `currentHistorySample`).
  public var raw: [String: JSONValue]
  public var statsHistory: [ContainerStatsHistorySample]?
  public var currentHistorySample: ContainerStatsHistorySample

  private static let knownKeys: Set<String> = ["statsHistory", "currentHistorySample"]

  public init(
    raw: [String: JSONValue] = [:],
    statsHistory: [ContainerStatsHistorySample]? = nil,
    currentHistorySample: ContainerStatsHistorySample = .init()
  ) {
    self.raw = raw
    self.statsHistory = statsHistory
    self.currentHistorySample = currentHistorySample
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let object = try container.decode([String: JSONValue].self)

    if case .array(let history)? = object["statsHistory"] {
      let encoder = JSONEncoder()
      let decoder = JSONDecoder()
      var samples: [ContainerStatsHistorySample] = []
      samples.reserveCapacity(history.count)
      for item in history {
        let data = try encoder.encode(item)
        samples.append(try decoder.decode(ContainerStatsHistorySample.self, from: data))
      }
      self.statsHistory = samples
    } else {
      self.statsHistory = nil
    }

    if let sample = object["currentHistorySample"] {
      let data = try JSONEncoder().encode(sample)
      self.currentHistorySample = try JSONDecoder().decode(
        ContainerStatsHistorySample.self, from: data)
    } else {
      self.currentHistorySample = .init()
    }

    self.raw = object.filter { !Self.knownKeys.contains($0.key) }
  }

  public func encode(to encoder: Encoder) throws {
    var merged = raw
    if let statsHistory {
      let data = try JSONEncoder().encode(statsHistory)
      merged["statsHistory"] = try JSONDecoder().decode(JSONValue.self, from: data)
    }
    let currentData = try JSONEncoder().encode(currentHistorySample)
    merged["currentHistorySample"] = try JSONDecoder().decode(JSONValue.self, from: currentData)

    var container = encoder.singleValueContainer()
    try container.encode(merged)
  }
}
