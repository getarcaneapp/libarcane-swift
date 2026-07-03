import Foundation

public final class TerminalSession: Sendable {
  private let channel: WebSocketChannel<String, Data>

  private init(channel: WebSocketChannel<String, Data>) {
    self.channel = channel
  }

  public var output: AsyncThrowingStream<Data, Error> {
    channel.messages
  }

  public static func connect(transport: ArcaneURLSessionTransport, path: String, shell: String)
    async throws -> TerminalSession
  {
    let request = try await transport.websocketRequest(
      path: path, query: [URLQueryItem(name: "shell", value: shell)])
    let channel = WebSocketChannel<String, Data>(
      request: request,
      session: transport.session,
      encodeOutbound: { .string($0) },
      decodeInbound: { message in
        switch message {
        case .string(let text):
          return Data(text.utf8)
        case .data(let data):
          return data
        @unknown default:
          throw ArcaneError.transport("Unsupported terminal frame")
        }
      }
    )
    return TerminalSession(channel: channel)
  }

  public func send(_ text: String) async throws {
    try await channel.send(text)
  }

  public func close() async {
    await channel.close()
  }
}
