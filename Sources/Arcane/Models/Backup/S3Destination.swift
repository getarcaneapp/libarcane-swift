import Foundation

public struct S3Destination: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var name: String
  public var endpoint: String?
  public var bucket: String
  public var region: String
  public var accessKeyId: String
  public var prefix: String?
  public var useSsl: Bool
  public var forcePathStyle: Bool
  public var secretConfigured: Bool
  public var createdAt: Date
  public var updatedAt: Date?

  public init(
    id: String,
    name: String,
    endpoint: String? = nil,
    bucket: String,
    region: String,
    accessKeyId: String,
    prefix: String? = nil,
    useSsl: Bool,
    forcePathStyle: Bool,
    secretConfigured: Bool,
    createdAt: Date,
    updatedAt: Date? = nil
  ) {
    self.id = id
    self.name = name
    self.endpoint = endpoint
    self.bucket = bucket
    self.region = region
    self.accessKeyId = accessKeyId
    self.prefix = prefix
    self.useSsl = useSsl
    self.forcePathStyle = forcePathStyle
    self.secretConfigured = secretConfigured
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}
