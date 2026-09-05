public struct S3DestinationUsage: Codable, Hashable, Sendable {
  public var inUse: Bool
  public init(inUse: Bool) { self.inUse = inUse }
}
