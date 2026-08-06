import Foundation

/// Per-request Arcane API metadata.
public struct ArcaneRequestOptions: Hashable, Sendable {
  public enum ValidationError: Error, Equatable, Sendable {
    case invalidActivityBatchID
  }

  public let activityBatchID: String?
  let stepUpToken: String?

  public init() {
    self.activityBatchID = nil
    self.stepUpToken = nil
  }

  public init(activityBatchID: String) throws {
    guard Self.isValidActivityBatchID(activityBatchID) else {
      throw ValidationError.invalidActivityBatchID
    }
    self.activityBatchID = activityBatchID
    self.stepUpToken = nil
  }

  init(stepUpToken: String) {
    self.activityBatchID = nil
    self.stepUpToken = stepUpToken
  }

  private static func isValidActivityBatchID(_ value: String) -> Bool {
    guard (1...64).contains(value.utf8.count) else { return false }
    return value.utf8.allSatisfy { byte in
      (byte >= 48 && byte <= 57)
        || (byte >= 65 && byte <= 90)
        || (byte >= 97 && byte <= 122)
        || byte == 95
        || byte == 45
    }
  }
}
