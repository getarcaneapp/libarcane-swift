import Foundation

/// A project's effective tag, including its UI and Compose sources.
public struct ProjectTag: Codable, Hashable, Sendable {
  public var name: String
  public var color: String
  public var sources: [String]

  public init(name: String, color: String, sources: [String] = []) {
    self.name = name
    self.color = color
    self.sources = sources
  }
}
