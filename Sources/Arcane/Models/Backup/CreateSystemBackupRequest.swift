import Foundation

public struct CreateSystemBackupRequest: Codable, Hashable, Sendable {
  public var destination: String?
  public var s3DestinationId: String?
  public var recoveryKey: String?
  public var policyId: String?

  public init(
    destination: String? = nil,
    s3DestinationId: String? = nil,
    recoveryKey: String? = nil,
    policyId: String? = nil
  ) {
    self.destination = destination
    self.s3DestinationId = s3DestinationId
    self.recoveryKey = recoveryKey
    self.policyId = policyId
  }
}
