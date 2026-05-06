import Foundation

public final class WebSocketChannel<Outbound: Sendable, Inbound: Sendable>: @unchecked Sendable {
    private let task: URLSessionWebSocketTask
    private let encodeOutbound: @Sendable (Outbound) throws -> URLSessionWebSocketTask.Message
    private let decodeInbound: @Sendable (URLSessionWebSocketTask.Message) throws -> Inbound

    public init(
        request: URLRequest,
        session: URLSession = .shared,
        encodeOutbound: @escaping @Sendable (Outbound) throws -> URLSessionWebSocketTask.Message,
        decodeInbound: @escaping @Sendable (URLSessionWebSocketTask.Message) throws -> Inbound
    ) {
        self.task = session.webSocketTask(with: request)
        self.encodeOutbound = encodeOutbound
        self.decodeInbound = decodeInbound
        self.task.resume()
    }

    public var messages: AsyncThrowingStream<Inbound, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    while !Task.isCancelled {
                        let message = try await task.receive()
                        continuation.yield(try decodeInbound(message))
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    public func send(_ value: Outbound) async throws {
        try await task.send(try encodeOutbound(value))
    }

    public func close(code: URLSessionWebSocketTask.CloseCode = .normalClosure, reason: Data? = nil) async {
        task.cancel(with: code, reason: reason)
    }
}
