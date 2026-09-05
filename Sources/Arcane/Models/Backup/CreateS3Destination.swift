import Foundation

public struct CreateS3Destination: Codable, Hashable, Sendable {
  public var name: String
  public var endpoint: String?
  public var bucket: String
  public var region: String
  public var accessKeyId: String
  public var secretAccessKey: String
  public var prefix: String?
  public var useSsl: Bool
  public var forcePathStyle: Bool

  public init(
    name: String,
    endpoint: String? = nil,
    bucket: String,
    region: String,
    accessKeyId: String,
    secretAccessKey: String,
    prefix: String? = nil,
    useSsl: Bool,
    forcePathStyle: Bool
  ) {
    self.name = name
    self.endpoint = endpoint
    self.bucket = bucket
    self.region = region
    self.accessKeyId = accessKeyId
    self.secretAccessKey = secretAccessKey
    self.prefix = prefix
    self.useSsl = useSsl
    self.forcePathStyle = forcePathStyle
  }
}
