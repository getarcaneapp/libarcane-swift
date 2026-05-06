import Foundation

public enum ArcaneError: Error, Sendable, Equatable {
    case unauthorized
    case forbidden
    case notFound
    case conflict(message: String?)
    case validation(fields: [String: [String]])
    case rateLimited(retryAfter: TimeInterval?)
    case server(code: String, message: String)
    case transport(String)
    case decoding(String)
    case unknown(statusCode: Int, body: String)
}

public struct APIErrorResponse: Decodable, Sendable {
    public var success: Bool?
    public var error: String?
    public var message: String?
    public var code: String?
    public var details: JSONValue?
}

extension ArcaneError {
    static func from(statusCode: Int, data: Data, headers: [AnyHashable: Any], decoder: JSONDecoder) -> ArcaneError {
        let body = String(data: data, encoding: .utf8) ?? ""
        let error = try? decoder.decode(APIErrorResponse.self, from: data)
        let message = error?.error ?? error?.message ?? body
        let code = error?.code ?? httpCode(statusCode)

        switch statusCode {
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 409:
            return .conflict(message: message.isEmpty ? nil : message)
        case 400 where code == "VALIDATION_ERROR":
            return .validation(fields: validationFields(from: error?.details))
        case 429:
            return .rateLimited(retryAfter: retryAfter(from: headers))
        case 500...599:
            return .server(code: code, message: message)
        default:
            if let error, let code = error.code {
                return .server(code: code, message: message)
            }
            return .unknown(statusCode: statusCode, body: body)
        }
    }

    private static func httpCode(_ statusCode: Int) -> String {
        switch statusCode {
        case 400: "BAD_REQUEST"
        case 401: "UNAUTHORIZED"
        case 403: "FORBIDDEN"
        case 404: "NOT_FOUND"
        case 409: "CONFLICT"
        case 504: "TIMEOUT"
        default: "HTTP_\(statusCode)"
        }
    }

    private static func retryAfter(from headers: [AnyHashable: Any]) -> TimeInterval? {
        guard let raw = headers["Retry-After"] as? String else {
            return nil
        }
        return TimeInterval(raw)
    }

    private static func validationFields(from details: JSONValue?) -> [String: [String]] {
        guard case let .object(object)? = details else {
            return [:]
        }
        var fields: [String: [String]] = [:]
        for (key, value) in object {
            switch value {
            case let .string(message):
                fields[key] = [message]
            case let .array(items):
                fields[key] = items.compactMap {
                    if case let .string(message) = $0 { return message }
                    return nil
                }
            default:
                continue
            }
        }
        return fields
    }
}

public enum JSONValue: Codable, Hashable, Sendable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: JSONValue].self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case let .bool(value):
            try container.encode(value)
        case let .number(value):
            try container.encode(value)
        case let .string(value):
            try container.encode(value)
        case let .array(value):
            try container.encode(value)
        case let .object(value):
            try container.encode(value)
        }
    }
}
