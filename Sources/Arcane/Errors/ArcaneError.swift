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

func normalizedTransportError(_ error: Error) -> Error {
  if error is CancellationError {
    return CancellationError()
  }
  if let urlError = error as? URLError, urlError.code == .cancelled {
    return CancellationError()
  }
  if let arcaneError = error as? ArcaneError {
    return arcaneError
  }
  if let urlError = error as? URLError {
    return ArcaneError.transport(urlError.localizedDescription)
  }
  return error
}

public struct APIErrorResponse: Decodable, Sendable {
  public var success: Bool?
  public var error: String?
  public var message: String?
  public var code: String?
  public var details: JSONValue?
}

struct HumaErrorResponse: Decodable, Sendable {
  var title: String?
  var status: Int?
  var detail: String?
  var errors: [HumaErrorDetail]?
}

struct HumaErrorDetail: Decodable, Sendable {
  var message: String?
  var location: String?
  var value: JSONValue?
}

extension ArcaneError {
  static func from(statusCode: Int, data: Data, headers: [AnyHashable: Any], decoder: JSONDecoder)
    -> ArcaneError
  {
    let body = String(data: data, encoding: .utf8) ?? ""
    let arcaneError = try? decoder.decode(APIErrorResponse.self, from: data)
    let arcaneHasFields =
      arcaneError?.error != nil || arcaneError?.message != nil || arcaneError?.code != nil
    let humaError: HumaErrorResponse? =
      arcaneHasFields ? nil : try? decoder.decode(HumaErrorResponse.self, from: data)
    let humaMessage = humaError?.detail ?? humaError?.title
    let message = arcaneError?.error ?? arcaneError?.message ?? humaMessage ?? body
    let code = arcaneError?.code ?? httpCode(statusCode)

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
      return .validation(fields: validationFields(from: arcaneError?.details))
    case 422:
      if let humaErrors = humaError?.errors, !humaErrors.isEmpty {
        return .validation(fields: validationFields(fromHuma: humaErrors))
      }
      return .server(code: code, message: humaMessage ?? message)
    case 429:
      return .rateLimited(retryAfter: retryAfter(from: headers))
    case 500...599:
      return .server(code: code, message: message)
    default:
      return fallbackError(
        statusCode: statusCode,
        message: message,
        arcaneError: arcaneError,
        humaMessage: humaMessage,
        body: body
      )
    }
  }

  private static func fallbackError(
    statusCode: Int,
    message: String,
    arcaneError: APIErrorResponse?,
    humaMessage: String?,
    body: String
  ) -> ArcaneError {
    let code = arcaneError?.code ?? httpCode(statusCode)
    if let arcaneError, let code = arcaneError.code {
      return .server(code: code, message: message)
    }
    if let humaMessage, !humaMessage.isEmpty {
      return .server(code: code, message: humaMessage)
    }
    return .unknown(statusCode: statusCode, body: body)
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
    guard case .object(let object)? = details else {
      return [:]
    }
    var fields: [String: [String]] = [:]
    for (key, value) in object {
      switch value {
      case .string(let message):
        fields[key] = [message]
      case .array(let items):
        fields[key] = items.compactMap {
          if case .string(let message) = $0 { return message }
          return nil
        }
      default:
        continue
      }
    }
    return fields
  }

  private static func validationFields(fromHuma errors: [HumaErrorDetail]) -> [String: [String]] {
    var fields: [String: [String]] = [:]
    for detail in errors {
      let name = stripLocationPrefix(detail.location ?? "request")
      let message = detail.message ?? "Invalid value"
      fields[name, default: []].append(message)
    }
    return fields
  }

  private static func stripLocationPrefix(_ location: String) -> String {
    for prefix in ["body.", "query.", "path.", "header.", "cookie."]
    where location.hasPrefix(prefix) {
      return String(location.dropFirst(prefix.count))
    }
    return location
  }
}
