import Foundation
import Synchronization

private final class WebSocketIteratorState<Element: Sendable>: Sendable {
  typealias Channel = WebSocketChannel<Never, Element>

  private struct State {
    var channel: Channel?
    var cancelled = false
  }
  private let state = Mutex(State())

  func install(channel: Channel) -> Bool {
    state.withLock {
      guard !$0.cancelled else { return false }
      $0.channel = channel
      return true
    }
  }

  func cancel() {
    let channel = state.withLock { state -> Channel? in
      guard !state.cancelled else { return nil }
      state.cancelled = true
      defer { state.channel = nil }
      return state.channel
    }
    channel?.closeImmediately()
  }

  deinit { cancel() }
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

  /// A single-consumer iterator. Create a separate iterator for each consuming task.
  public final class Iterator: AsyncIteratorProtocol {
    private let transport: ArcaneURLSessionTransport
    private let path: String
    private let query: [URLQueryItem]
    private let state = WebSocketIteratorState<LogLine>()
    private var iterator: AsyncThrowingStream<LogLine, Error>.Iterator?
    private var finished = false

    fileprivate init(transport: ArcaneURLSessionTransport, path: String, query: [URLQueryItem]) {
      self.transport = transport
      self.path = path
      self.query = query
    }

    public func next() async throws -> LogLine? {
      try Task.checkCancellation()
      guard !finished else { return nil }
      if iterator == nil {
        var request = try await transport.websocketRequest(path: path, query: query)
        let proxyDelegate = try await transport.proxySupport.prepare(&request)
        let decoder = ArcaneJSON.makeDecoder()
        let channel = WebSocketChannel<Never, LogLine>(
          request: request,
          session: transport.session,
          delegate: proxyDelegate,
          encodeOutbound: { _ in fatalError("Log streams are receive-only") },
          decodeInbound: { message in
            switch message {
            case .string(let text):
              if let data = text.data(using: .utf8),
                let json = try? decoder.decode(LogLineMessage.self, from: data) {
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
        guard state.install(channel: channel) else {
          channel.closeImmediately()
          throw CancellationError()
        }
        iterator = channel.messages.makeAsyncIterator()
      }

      return try await withTaskCancellationHandler {
        do {
          guard var iterator else { return nil }
          let value = try await iterator.next(isolation: #isolation)
          self.iterator = iterator
          if value == nil {
            finished = true
            self.iterator = nil
            state.cancel()
          }
          return value
        } catch {
          finished = true
          iterator = nil
          state.cancel()
          throw normalizedTransportError(error)
        }
      } onCancel: { [state] in
        state.cancel()
      }
    }

    deinit {
      state.cancel()
    }
  }

  static func query(follow: Bool, tail: String, since: String?, timestamps: Bool) -> [URLQueryItem] {
    var query = [
      URLQueryItem(name: "follow", value: follow ? "true" : "false"),
      URLQueryItem(name: "tail", value: tail),
      URLQueryItem(name: "timestamps", value: timestamps ? "true" : "false")
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

  /// A single-consumer iterator. Create a separate iterator for each consuming task.
  public final class Iterator: AsyncIteratorProtocol {
    private let transport: ArcaneURLSessionTransport
    private let path: String
    private let query: [URLQueryItem]
    private let state = WebSocketIteratorState<Element>()
    private var iterator: AsyncThrowingStream<Element, Error>.Iterator?
    private var finished = false

    fileprivate init(transport: ArcaneURLSessionTransport, path: String, query: [URLQueryItem]) {
      self.transport = transport
      self.path = path
      self.query = query
    }

    public func next() async throws -> Element? {
      try Task.checkCancellation()
      guard !finished else { return nil }
      if iterator == nil {
        var request = try await transport.websocketRequest(path: path, query: query)
        let proxyDelegate = try await transport.proxySupport.prepare(&request)
        let decoder = ArcaneJSON.makeDecoder()
        let channel = WebSocketChannel<Never, Element>(
          request: request,
          session: transport.session,
          delegate: proxyDelegate,
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
        guard state.install(channel: channel) else {
          channel.closeImmediately()
          throw CancellationError()
        }
        iterator = channel.messages(bufferingPolicy: .bufferingNewest(1)).makeAsyncIterator()
      }

      return try await withTaskCancellationHandler {
        do {
          guard var iterator else { return nil }
          let value = try await iterator.next(isolation: #isolation)
          self.iterator = iterator
          if value == nil {
            finished = true
            self.iterator = nil
            state.cancel()
          }
          return value
        } catch {
          finished = true
          iterator = nil
          state.cancel()
          throw normalizedTransportError(error)
        }
      } onCancel: { [state] in
        state.cancel()
      }
    }

    deinit {
      state.cancel()
    }
  }
}
