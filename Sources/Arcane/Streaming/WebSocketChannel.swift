import Foundation

struct WebSocketOperations: Sendable {
    let receive: @Sendable () async throws -> URLSessionWebSocketTask.Message
    let send: @Sendable (URLSessionWebSocketTask.Message) async throws -> Void
    let close: @Sendable (URLSessionWebSocketTask.CloseCode, Data?) async -> Void
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

    func close(code: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        task.cancel(with: code, reason: reason)
    }
}

public final class WebSocketChannel<Outbound: Sendable, Inbound: Sendable>: Sendable {
    private let operations: WebSocketOperations
    private let encodeOutbound: @Sendable (Outbound) throws -> URLSessionWebSocketTask.Message
    private let decodeInbound: @Sendable (URLSessionWebSocketTask.Message) throws -> Inbound

    public init(
        request: URLRequest,
        session: URLSession = .shared,
        encodeOutbound: @escaping @Sendable (Outbound) throws -> URLSessionWebSocketTask.Message,
        decodeInbound: @escaping @Sendable (URLSessionWebSocketTask.Message) throws -> Inbound
    ) {
        let task = session.webSocketTask(with: request)
        task.resume()
        let driver = WebSocketTaskDriver(task: task)
        self.operations = WebSocketOperations(
            receive: { try await driver.receive() },
            send: { try await driver.send($0) },
            close: { code, reason in await driver.close(code: code, reason: reason) }
        )
        self.encodeOutbound = encodeOutbound
        self.decodeInbound = decodeInbound
    }

    init(
        operations: WebSocketOperations,
        encodeOutbound: @escaping @Sendable (Outbound) throws -> URLSessionWebSocketTask.Message,
        decodeInbound: @escaping @Sendable (URLSessionWebSocketTask.Message) throws -> Inbound
    ) {
        self.operations = operations
        self.encodeOutbound = encodeOutbound
        self.decodeInbound = decodeInbound
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
            continuation.onTermination = { [operations] _ in
                reader.cancel()
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
