import Foundation

/// Default WebSocket keepalive ping interval. The server emits 15s app-level
/// heartbeats that satisfy `timeoutIntervalForRequest`, but intermediate
/// proxies / NAT can drop an idle TCP connection without RST, leaving
/// `receive()` hung until the OS TCP timeout (minutes). Periodic protocol
/// pings surface those dead connections within one interval so callers can
/// reconnect instead of stalling silently.
public let arcaneWebSocketDefaultPingInterval: Duration = .seconds(25)

struct WebSocketOperations: Sendable {
    let receive: @Sendable () async throws -> URLSessionWebSocketTask.Message
    let send: @Sendable (URLSessionWebSocketTask.Message) async throws -> Void
    let sendPing: @Sendable () async throws -> Void
    let close: @Sendable (URLSessionWebSocketTask.CloseCode, Data?) async -> Void
}

/// One-shot claim flag for continuation-bridged callbacks that the system may
/// invoke more than once. Lock-based because the callback arrives on an
/// arbitrary URLSession queue.
private final class ContinuationResumeGuard: @unchecked Sendable {
    private let lock = NSLock()
    private var claimed = false

    /// True exactly once; every later call returns false.
    func tryClaim() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if claimed { return false }
        claimed = true
        return true
    }
}

private actor WebSocketTaskDriver {
    private let task: URLSessionWebSocketTask

    init(task: URLSessionWebSocketTask) {
        self.task = task
    }

    func receive() async throws -> URLSessionWebSocketTask.Message {
        try await task.receive()
    }

    func send(_ message: URLSessionWebSocketTask.Message) async throws {
        try await task.send(message)
    }

    func sendPing() async throws {
        // URLSessionWebSocketTask.sendPing can invoke its completion handler
        // more than once when the connection resets mid-ping (long-standing
        // Foundation bug — surfaces as "Connection reset by peer" followed by
        // a SWIFT TASK CONTINUATION MISUSE crash). Only the first callback may
        // resume the continuation; later ones are dropped.
        let resumeGuard = ContinuationResumeGuard()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            task.sendPing { error in
                guard resumeGuard.tryClaim() else { return }
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func close(code: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        task.cancel(with: code, reason: reason)
    }
}

public final class WebSocketChannel<Outbound: Sendable, Inbound: Sendable>: Sendable {
    private let operations: WebSocketOperations
    private let encodeOutbound: @Sendable (Outbound) throws -> URLSessionWebSocketTask.Message
    private let decodeInbound: @Sendable (URLSessionWebSocketTask.Message) throws -> Inbound
    private let pingInterval: Duration?

    public init(
        request: URLRequest,
        session: URLSession = .shared,
        pingInterval: Duration? = arcaneWebSocketDefaultPingInterval,
        encodeOutbound: @escaping @Sendable (Outbound) throws -> URLSessionWebSocketTask.Message,
        decodeInbound: @escaping @Sendable (URLSessionWebSocketTask.Message) throws -> Inbound
    ) {
        let task = session.webSocketTask(with: request)
        task.resume()
        let driver = WebSocketTaskDriver(task: task)
        self.operations = WebSocketOperations(
            receive: { try await driver.receive() },
            send: { try await driver.send($0) },
            sendPing: { try await driver.sendPing() },
            close: { code, reason in await driver.close(code: code, reason: reason) }
        )
        self.encodeOutbound = encodeOutbound
        self.decodeInbound = decodeInbound
        self.pingInterval = pingInterval
    }

    init(
        operations: WebSocketOperations,
        pingInterval: Duration? = nil,
        encodeOutbound: @escaping @Sendable (Outbound) throws -> URLSessionWebSocketTask.Message,
        decodeInbound: @escaping @Sendable (URLSessionWebSocketTask.Message) throws -> Inbound
    ) {
        self.operations = operations
        self.encodeOutbound = encodeOutbound
        self.decodeInbound = decodeInbound
        self.pingInterval = pingInterval
    }

    /// A single-consumer stream for this websocket connection.
    ///
    /// Access this once per `WebSocketChannel` instance. When the returned stream
    /// terminates, the channel closes the underlying websocket task. Create a new
    /// channel for reconnect or retry attempts.
    public var messages: AsyncThrowingStream<Inbound, Error> {
        AsyncThrowingStream { continuation in
            let reader = Task {
                do {
                    while !Task.isCancelled {
                        let message = try await operations.receive()
                        continuation.yield(try decodeInbound(message))
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            let pinger: Task<Void, Never>?
            if let pingInterval {
                pinger = Task {
                    while !Task.isCancelled {
                        try? await Task.sleep(for: pingInterval)
                        if Task.isCancelled { break }
                        do {
                            try await operations.sendPing()
                        } catch {
                            // Ping failure means the connection is dead — surface
                            // it so the consumer can reconnect instead of hanging
                            // on a silently-dropped socket.
                            continuation.finish(throwing: error)
                            break
                        }
                    }
                }
            } else {
                pinger = nil
            }
            continuation.onTermination = { [operations] _ in
                reader.cancel()
                pinger?.cancel()
                Task {
                    await operations.close(.normalClosure, nil)
                }
            }
        }
    }

    public func send(_ value: Outbound) async throws {
        try await operations.send(try encodeOutbound(value))
    }

    public func close(code: URLSessionWebSocketTask.CloseCode = .normalClosure, reason: Data? = nil) async {
        await operations.close(code, reason)
    }
}
