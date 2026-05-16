import Foundation

public struct MessageResponse: Codable, Hashable, Sendable {
    public var message: String

    public init(message: String) {
        self.message = message
    }
}

public struct ErrorResponse: Codable, Hashable, Sendable {
    public var error: String

    public init(error: String) {
        self.error = error
    }
}

public struct ErrorModel: Codable, Hashable, Sendable {
    public var title: String?
    public var status: Int?
    public var detail: String?
    public var instance: String?
    public var type: String?
    public var errors: [ErrorDetail]?

    public init(
        title: String? = nil,
        status: Int? = nil,
        detail: String? = nil,
        instance: String? = nil,
        type: String? = nil,
        errors: [ErrorDetail]? = nil
    ) {
        self.title = title
        self.status = status
        self.detail = detail
        self.instance = instance
        self.type = type
        self.errors = errors
    }
}

public struct ErrorDetail: Codable, Hashable, Sendable {
    public var message: String?
    public var location: String?
    public var value: JSONValue?

    public init(message: String? = nil, location: String? = nil, value: JSONValue? = nil) {
        self.message = message
        self.location = location
        self.value = value
    }
}
