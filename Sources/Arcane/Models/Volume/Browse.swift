import Foundation

/// FileEntry represents a single file or directory inside a volume.
public struct FileEntry: Codable, Hashable, Sendable {
    public var name: String
    public var path: String
    public var isDirectory: Bool
    public var size: Int64
    public var modTime: Date
    public var mode: String
    public var isSymlink: Bool
    public var linkTarget: String?

    public init(
        name: String,
        path: String,
        isDirectory: Bool,
        size: Int64,
        modTime: Date,
        mode: String,
        isSymlink: Bool = false,
        linkTarget: String? = nil
    ) {
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.size = size
        self.modTime = modTime
        self.mode = mode
        self.isSymlink = isSymlink
        self.linkTarget = linkTarget
    }
}

/// FileMetadata extends ``FileEntry`` with MIME and text/binary hints.
public struct FileMetadata: Codable, Hashable, Sendable {
    public var name: String
    public var path: String
    public var isDirectory: Bool
    public var size: Int64
    public var modTime: Date
    public var mode: String
    public var isSymlink: Bool
    public var linkTarget: String?
    public var mimeType: String
    public var isText: Bool
    public var isBinary: Bool

    public init(
        name: String,
        path: String,
        isDirectory: Bool,
        size: Int64,
        modTime: Date,
        mode: String,
        isSymlink: Bool = false,
        linkTarget: String? = nil,
        mimeType: String,
        isText: Bool,
        isBinary: Bool
    ) {
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.size = size
        self.modTime = modTime
        self.mode = mode
        self.isSymlink = isSymlink
        self.linkTarget = linkTarget
        self.mimeType = mimeType
        self.isText = isText
        self.isBinary = isBinary
    }
}

/// FileContent is the response payload returned by ``GET volumes/{name}/browse/content``.
public struct FileContent: Codable, Hashable, Sendable {
    /// Base64-encoded file bytes.
    public var content: Data
    public var mimeType: String

    public init(content: Data, mimeType: String) {
        self.content = content
        self.mimeType = mimeType
    }
}
