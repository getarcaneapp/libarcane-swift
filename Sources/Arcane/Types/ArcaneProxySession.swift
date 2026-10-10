import Foundation

/// An app-owned cookie snapshot. The generation lets the app ignore responses
/// from requests that started before the proxy session was cleared or replaced.
public struct ArcaneProxyRequestContext: Sendable, CustomStringConvertible,
  CustomDebugStringConvertible {
  public let headers: [String: String]
  public let generation: UInt64
  /// False retires an old client before it can send saved proxy headers.
  public let isValid: Bool

  public var description: String {
    "ArcaneProxyRequestContext(generation: \(generation), headers: [redacted])"
  }
  public var debugDescription: String { description }

  public init(headers: [String: String], generation: UInt64, isValid: Bool = true) {
    self.headers = headers
    self.generation = generation
    self.isValid = isValid
  }
}

public protocol ArcaneProxySession: Sendable {
  func requestContext(for url: URL) async -> ArcaneProxyRequestContext
  func receive(response: HTTPURLResponse, for url: URL, generation: UInt64) async
}
