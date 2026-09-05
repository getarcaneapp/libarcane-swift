import Foundation

public enum UploadKind: String, Codable, Sendable {
  case image
  case volumeBackup = "volume-backup"
  case buildWorkspace = "build-workspace"
}

public struct UploadSession: Decodable, Sendable, Identifiable {
  public let id: String
  public let kind: UploadKind
  public let filename: String
  public let size: Int64
  public let chunkSize: Int
  public let totalChunks: Int
  public let receivedChunks: [Int]
  public let complete: Bool
  public let createdAt: Date
}

public struct CreateUploadSession: Encodable, Sendable {
  public var filename: String
  public var size: Int64
  public init(filename: String, size: Int64) {
    self.filename = filename
    self.size = size
  }
}

public struct UploadProgress: Sendable {
  public let bytesDone: Int64
  public let totalBytes: Int64
}
