import Foundation

/// MobilePushService pairs this device with the Arcane server for native push
/// notifications. All endpoints live under `/apns` and act on the calling user.
public struct MobilePushService: Sendable {
  private let rest: RESTService

  init(rest: RESTService) {
    self.rest = rest
  }

  /// Whether mobile push is enabled server-side plus the caller's devices.
  public func status() async throws -> MobilePushStatus {
    try await rest.get("apns/status")
  }

  /// Issues a short-lived signed pairing token for the push relay.
  public func pairingToken() async throws -> MobilePushPairingToken {
    try await rest.post("apns/pairing-token", body: Optional<EmptyBody>.none)
  }

  /// Registers the relay `recipientId` returned by pairing.
  public func registerDevice(_ body: MobilePushRegisterDevice) async throws -> MobilePushDevice {
    try await rest.post("apns/devices", body: body)
  }

  public func updateDevice(id: String, body: MobilePushUpdateDevice) async throws -> MobilePushDevice {
    try await rest.patch("apns/devices/\(id)", body: body)
  }

  public func deleteDevice(id: String) async throws {
    try await rest.deleteVoid("apns/devices/\(id)")
  }

  /// Sends a test notification to one of the caller's devices.
  public func testDevice(id: String) async throws {
    try await rest.postVoid("apns/devices/\(id)/test", body: Optional<EmptyBody>.none)
  }
}
