import Foundation

/// Response body for ``GET /environments/{id}/builds/browse/content``.
public struct BuildFileContent: Codable, Hashable, Sendable {
    /// Base64-encoded file bytes.
    public var content: Data
    public var mimeType: String

    public init(content: Data, mimeType: String) {
        self.content = content
        self.mimeType = mimeType
    }
}
