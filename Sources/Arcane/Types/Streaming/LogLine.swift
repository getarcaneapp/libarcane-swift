import Foundation

public struct LogLine: Codable, Hashable, Sendable {
  public var text: String
  public var seq: UInt64?
  public var level: String?
  public var service: String?
  public var timestamp: String?
}

/// A `LogLine` paired with a stable monotonic identifier assigned at receive time,
/// suitable for use as a SwiftUI `ForEach` element. `LogLine` itself has no unique
/// identity (text and timestamps may repeat), so consumers should wrap incoming
/// lines with a `nextID &+= 1` counter as they arrive.
public struct IdentifiedLogLine: Identifiable, Hashable, Sendable {
  public let id: UInt64
  public let line: LogLine

  public init(id: UInt64, line: LogLine) {
    self.id = id
    self.line = line
  }
}
