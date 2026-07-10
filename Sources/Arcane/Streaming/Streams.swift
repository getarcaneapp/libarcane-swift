import Foundation

private final class WebSocketIteratorState<Element: Sendable>: @unchecked Sendable {
  typealias Channel = WebSocketChannel<Never, Element>
  typealias Iterator = AsyncThrowingStream<Element, Error>.Iterator

  private let lock = NSLock()
  private var channel: Channel?
  private var iterator: Iterator?
  private var cancelled = false

  func currentIterator() -> Iterator? {
    lock.lock()
    defer { lock.unlock() }
    return iterator
  }

  func install(channel: Channel, iterator: Iterator) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    guard !cancelled else { return false }
    self.channel = channel
    self.iterator = iterator
    return true
  }

  func update(_ iterator: Iterator) {
    lock.lock()
    defer { lock.unlock() }
    guard !cancelled else { return }
    self.iterator = iterator
  }

  func cancel() {
    let channel: Channel?
    lock.lock()
    if cancelled {
      lock.unlock()
      return
    }
    cancelled = true
    channel = self.channel
    self.channel = nil
    iterator = nil
    lock.unlock()
    channel?.closeImmediately()
  }

  deinit {
    cancel()
  }
}

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
  public typealias AsyncIterator = Iterator

  private let transport: ArcaneURLSessionTransport
  private let path: String
  private let query: [URLQueryItem]

  init(transport: ArcaneURLSessionTransport, path: String, query: [URLQueryItem]) {
    self.transport = transport
    self.path = path
    self.query = query + [URLQueryItem(name: "format", value: "json")]
  }

  public func makeAsyncIterator() -> Iterator {
    Iterator(transport: transport, path: path, query: query)
  }

  public final class Iterator: AsyncIteratorProtocol, @unchecked Sendable {
    private let transport: ArcaneURLSessionTransport
    private let path: String
    private let query: [URLQueryItem]
    private let state = WebSocketIteratorState<LogLine>()

    fileprivate init(transport: ArcaneURLSessionTransport, path: String, query: [URLQueryItem]) {
      self.transport = transport
      self.path = path
      self.query = query
    }

    public func next() async throws -> LogLine? {
      try Task.checkCancellation()
      if state.currentIterator() == nil {
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
        guard
          state.install(
            channel: channel,
            iterator: channel.messages.makeAsyncIterator()
          )
        else {
          channel.closeImmediately()
          throw CancellationError()
        }
      }

      return try await withTaskCancellationHandler {
        do {
          guard var iterator = state.currentIterator() else { return nil }
          let value = try await iterator.next()
          state.update(iterator)
          if value == nil { state.cancel() }
          return value
        } catch {
          state.cancel()
          throw normalizedTransportError(error)
        }
      } onCancel: {
        self.state.cancel()
      }
    }

    deinit {
      state.cancel()
    }
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
  public typealias AsyncIterator = Iterator

  private let transport: ArcaneURLSessionTransport
  private let path: String
  private let query: [URLQueryItem]

  init(transport: ArcaneURLSessionTransport, path: String, query: [URLQueryItem] = []) {
    self.transport = transport
    self.path = path
    self.query = query
  }

  public func makeAsyncIterator() -> Iterator {
    Iterator(transport: transport, path: path, query: query)
  }

  public final class Iterator: AsyncIteratorProtocol, @unchecked Sendable {
    private let transport: ArcaneURLSessionTransport
    private let path: String
    private let query: [URLQueryItem]
    private let state = WebSocketIteratorState<Element>()

    fileprivate init(transport: ArcaneURLSessionTransport, path: String, query: [URLQueryItem]) {
      self.transport = transport
      self.path = path
      self.query = query
    }

    public func next() async throws -> Element? {
      try Task.checkCancellation()
      if state.currentIterator() == nil {
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
        guard
          state.install(
            channel: channel,
            iterator: channel.messages(bufferingPolicy: .bufferingNewest(1)).makeAsyncIterator()
          )
        else {
          channel.closeImmediately()
          throw CancellationError()
        }
      }

      return try await withTaskCancellationHandler {
        do {
          guard var iterator = state.currentIterator() else { return nil }
          let value = try await iterator.next()
          state.update(iterator)
          if value == nil { state.cancel() }
          return value
        } catch {
          state.cancel()
          throw normalizedTransportError(error)
        }
      } onCancel: {
        self.state.cancel()
      }
    }

    deinit {
      state.cancel()
    }
  }
}
