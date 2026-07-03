import Foundation

/// Health-check response. `status` is "UP" when healthy.
public struct HealthResponse: Codable, Hashable, Sendable {
  public var status: String

  public init(status: String) {
    self.status = status
  }
}
