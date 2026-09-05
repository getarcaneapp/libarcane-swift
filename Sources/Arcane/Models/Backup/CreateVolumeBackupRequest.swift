import Foundation

public struct CreateVolumeBackupRequest: Codable, Hashable, Sendable {
  public var destination: String?
  public var policyId: String?
  public var s3DestinationId: String?

  public init(
    destination: String? = nil,
    policyId: String? = nil,
    s3DestinationId: String? = nil
  ) {
    self.destination = destination
    self.policyId = policyId
    self.s3DestinationId = s3DestinationId
  }
}
