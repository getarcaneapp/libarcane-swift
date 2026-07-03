import Foundation

public struct LogLine: Codable, Hashable, Sendable {
  public var text: String
  public var seq: UInt64?
  public var level: String?
  public var service: String?
  public var timestamp: String?
}

/// A `LogLine` paired with a stable monotonic identifier assigned at receive time,
/// suitable for use as a SwiftUI `ForEach` element. `LogLine` itself has no unique
/// identity (text and timestamps may repeat), so consumers should wrap incoming
/// lines with a `nextID &+= 1` counter as they arrive.
public struct IdentifiedLogLine: Identifiable, Hashable, Sendable {
  public let id: UInt64
  public let line: LogLine

  public init(id: UInt64, line: LogLine) {
    self.id = id
    self.line = line
  }
}

public struct LogStream: AsyncSequence, Sendable {
  public typealias Element = LogLine

  private let transport: ArcaneURLSessionTransport
  private let path: String
  private let query: [URLQueryItem]

  init(transport: ArcaneURLSessionTransport, path: String, query: [URLQueryItem]) {
    self.transport = transport
    self.path = path
    self.query = query + [URLQueryItem(name: "format", value: "json")]
  }

  public func makeAsyncIterator() -> AsyncThrowingStream<LogLine, Error>.Iterator {
    AsyncThrowingStream<LogLine, Error> { continuation in
      Task {
        do {
          let request = try await transport.websocketRequest(path: path, query: query)
          let decoder = ArcaneJSON.makeDecoder()
          let channel = WebSocketChannel<Never, LogLine>(
            request: request,
            session: transport.session,
            encodeOutbound: { _ in fatalError("Log streams are receive-only") },
            decodeInbound: { message in
              switch message {
              case .string(let text):
                if let data = text.data(using: .utf8),
                  let json = try? decoder.decode(LogLineMessage.self, from: data)
                {
                  return LogLine(
                    text: json.message,
                    seq: json.seq,
                    level: json.level,
                    service: json.service,
                    timestamp: json.timestamp
                  )
                }
                return LogLine(text: text)
              case .data(let data):
                let json = try decoder.decode(LogLineMessage.self, from: data)
                return LogLine(
                  text: json.message,
                  seq: json.seq,
                  level: json.level,
                  service: json.service,
                  timestamp: json.timestamp
                )
              @unknown default:
                throw ArcaneError.transport("Unsupported WebSocket log frame")
              }
            }
          )
          for try await line in channel.messages {
            continuation.yield(line)
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
    }.makeAsyncIterator()
  }

  static func query(follow: Bool, tail: String, since: String?, timestamps: Bool) -> [URLQueryItem]
  {
    var query = [
      URLQueryItem(name: "follow", value: follow ? "true" : "false"),
      URLQueryItem(name: "tail", value: tail),
      URLQueryItem(name: "timestamps", value: timestamps ? "true" : "false"),
    ]
    if let since {
      query.append(URLQueryItem(name: "since", value: since))
    }
    return query
  }
}

private struct LogLineMessage: Codable {
  var seq: UInt64?
  var level: String?
  var message: String
  var service: String?
  var timestamp: String?
}

public struct StatsStream<Element: Decodable & Sendable>: AsyncSequence, Sendable {
  private let transport: ArcaneURLSessionTransport
  private let path: String
  private let query: [URLQueryItem]

  init(transport: ArcaneURLSessionTransport, path: String, query: [URLQueryItem] = []) {
    self.transport = transport
    self.path = path
    self.query = query
  }

  public func makeAsyncIterator() -> AsyncThrowingStream<Element, Error>.Iterator {
    AsyncThrowingStream<Element, Error> { continuation in
      Task {
        do {
          let request = try await transport.websocketRequest(path: path, query: query)
          let decoder = ArcaneJSON.makeDecoder()
          let channel = WebSocketChannel<Never, Element>(
            request: request,
            session: transport.session,
            encodeOutbound: { _ in fatalError("Stats streams are receive-only") },
            decodeInbound: { message in
              switch message {
              case .string(let text):
                guard let data = text.data(using: .utf8) else {
                  throw ArcaneError.decoding("Stats frame was not valid UTF-8")
                }
                return try decoder.decode(Element.self, from: data)
              case .data(let data):
                return try decoder.decode(Element.self, from: data)
              @unknown default:
                throw ArcaneError.transport("Unsupported WebSocket stats frame")
              }
            }
          )
          for try await frame in channel.messages {
            continuation.yield(frame)
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
    }.makeAsyncIterator()
  }
}
