import Foundation

/// Docker daemon version + system info as returned by `/system/docker/info`.
///
/// The fields below the top-level metadata mirror the Docker SDK's
/// `system.Info` struct, which the Go API embeds verbatim. Rather than
/// re-modeling every Docker SDK field, we expose the merged object as a
/// dictionary of `JSONValue`. Use the strongly-typed top-level fields for
/// the values Arcane massages itself.
public struct DockerInfo: Codable, Hashable, Sendable {
  public var success: Bool
  public var apiVersion: String
  public var gitCommit: String
  public var goVersion: String
  public var os: String
  public var arch: String
  public var buildTime: String

  /// Convenience access to commonly-used fields embedded from `system.Info`.
  public var ncpu: Int? {
    info?["NCPU"]?.intValue
  }

  public var memTotal: Int64? {
    info?["MemTotal"]?.int64Value
  }

  public var name: String? {
    info?["Name"]?.stringValue
  }

  public var serverVersion: String? {
    info?["ServerVersion"]?.stringValue
  }

  public var operatingSystem: String? {
    info?["OperatingSystem"]?.stringValue
  }

  /// Raw Docker SDK info payload. Nil when the API did not embed the info
  /// document (older deployments) — generally populated.
  public var info: [String: JSONValue]?

  public init(
    success: Bool,
    apiVersion: String,
    gitCommit: String,
    goVersion: String,
    os: String,
    arch: String,
    buildTime: String,
    info: [String: JSONValue]? = nil
  ) {
    self.success = success
    self.apiVersion = apiVersion
    self.gitCommit = gitCommit
    self.goVersion = goVersion
    self.os = os
    self.arch = arch
    self.buildTime = buildTime
    self.info = info
  }

  private static let topLevelKeys: Set<String> = [
    "success", "apiVersion", "gitCommit", "goVersion", "os", "arch", "buildTime",
  ]

  public init(from decoder: Decoder) throws {
    // Decode the entire payload as a JSON object so we can pull both the
    // top-level fields and the Docker SDK Info fields that are merged
    // alongside them.
    let container = try decoder.singleValueContainer()
    let raw = try container.decode([String: JSONValue].self)

    func string(_ key: String) -> String {
      raw[key]?.stringValue ?? ""
    }
    func bool(_ key: String) -> Bool {
      raw[key]?.boolValue ?? false
    }

    self.success = bool("success")
    self.apiVersion = string("apiVersion")
    self.gitCommit = string("gitCommit")
    self.goVersion = string("goVersion")
    self.os = string("os")
    self.arch = string("arch")
    self.buildTime = string("buildTime")

    var info: [String: JSONValue] = [:]
    for (key, value) in raw where !Self.topLevelKeys.contains(key) {
      info[key] = value
    }
    self.info = info.isEmpty ? nil : info
  }

  public func encode(to encoder: Encoder) throws {
    var raw: [String: JSONValue] = [
      "success": .bool(success),
      "apiVersion": .string(apiVersion),
      "gitCommit": .string(gitCommit),
      "goVersion": .string(goVersion),
      "os": .string(os),
      "arch": .string(arch),
      "buildTime": .string(buildTime),
    ]
    if let info {
      for (key, value) in info where !Self.topLevelKeys.contains(key) {
        raw[key] = value
      }
    }
    var container = encoder.singleValueContainer()
    try container.encode(raw)
  }
}
