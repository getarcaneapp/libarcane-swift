import Foundation

enum NDJSONStreamTerminalAction: Sendable {
  case continueStreaming
  case finish
  case fail(ArcaneError)
}

/// An `AsyncSequence` that consumes newline-delimited JSON (NDJSON / x-json-stream)
/// from a backend endpoint and yields decoded values. Used by streaming endpoints
/// like image pull/build, project operations, dashboard snapshots, and activities.
public struct NDJSONStream<Element: Decodable & Sendable>: AsyncSequence, Sendable {
  public typealias AsyncIterator = AsyncThrowingStream<Element, Error>.Iterator

  enum Source: Sendable {
    case body(method: String, body: Data?, contentType: String?, query: [URLQueryItem])
    case multipart(MultipartEndpoint)
  }

  private let transport: ArcaneURLSessionTransport
  private let path: String
  private let source: Source
  private let terminalAction: (@Sendable (Element) -> NDJSONStreamTerminalAction)?

  init(
    transport: ArcaneURLSessionTransport,
    path: String,
    method: String,
    body: Data?,
    contentType: String? = "application/json",
    query: [URLQueryItem] = [],
    terminalAction: (@Sendable (Element) -> NDJSONStreamTerminalAction)? = nil
  ) {
    self.transport = transport
    self.path = path
    self.source = .body(method: method, body: body, contentType: contentType, query: query)
    self.terminalAction = terminalAction
  }

  init(transport: ArcaneURLSessionTransport, multipart endpoint: MultipartEndpoint) {
    self.transport = transport
    self.path = endpoint.path
    self.source = .multipart(endpoint)
    self.terminalAction = nil
  }

  public func makeAsyncIterator() -> AsyncIterator {
    let transport = self.transport
    let path = self.path
    let source = self.source
    let terminalAction = self.terminalAction
    return AsyncThrowingStream<Element, Error> { continuation in
      let task = Task {
        do {
          let result = try await Self.openByteStream(
            transport: transport,
            path: path,
            source: source
          )
          defer { result.cleanup() }

          guard (200..<300).contains(result.http.statusCode) else {
            var snippet = Data()
            for try await byte in result.bytes {
              snippet.append(byte)
              if snippet.count > 4096 { break }
            }
            throw ArcaneError.from(
              statusCode: result.http.statusCode,
              data: snippet,
              headers: result.http.allHeaderFields,
              decoder: ArcaneJSON.makeDecoder()
            )
          }
          let decoder = ArcaneJSON.makeDecoder()
          for try await line in result.bytes.lines {
            if Task.isCancelled { break }
            guard let element = try Self.decodeLine(line, using: decoder) else { continue }
            switch terminalAction?(element) ?? .continueStreaming {
            case .continueStreaming:
              continuation.yield(element)
            case .finish:
              continuation.yield(element)
              continuation.finish()
              return
            case .fail(let error):
              throw error
            }
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: normalizedTransportError(error))
        }
      }
      continuation.onTermination = { _ in task.cancel() }
    }.makeAsyncIterator()
  }

  private static func decodeLine(_ line: String, using decoder: JSONDecoder) throws -> Element? {
    let trimmed = line.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8) else {
      return nil
    }
    do {
      return try decoder.decode(Element.self, from: data)
    } catch {
      // Non-JSON heartbeats, comments, and status text are intentionally
      // skipped. JSON decode failures indicate a schema mismatch.
      guard trimmed.hasPrefix("{") || trimmed.hasPrefix("[") else {
        return nil
      }
      throw ArcaneError.decoding(String(describing: error))
    }
  }

  private struct ByteStreamResult: Sendable {
    let bytes: URLSession.AsyncBytes
    let http: HTTPURLResponse
    let cleanup: @Sendable () -> Void
  }

  private static func openByteStream(
    transport: ArcaneURLSessionTransport,
    path: String,
    source: Source
  ) async throws -> ByteStreamResult {
    switch source {
    case .body(let method, let body, let contentType, let query):
      let (bytes, http) = try await transport.byteStream(
        path: path,
        method: method,
        query: query,
        body: body,
        contentType: contentType
      )
      return ByteStreamResult(bytes: bytes, http: http, cleanup: {})
    case .multipart(let endpoint):
      let prepared = try transport.makeMultipartTempFile(
        fields: endpoint.fields, files: endpoint.files)
      let cleanup: @Sendable () -> Void = {
        try? FileManager.default.removeItem(at: prepared.url)
      }
      do {
        let (bytes, http) = try await transport.multipartByteStream(
          path: endpoint.path,
          method: endpoint.method,
          query: endpoint.query,
          file: prepared
        )
        return ByteStreamResult(bytes: bytes, http: http, cleanup: cleanup)
      } catch {
        cleanup()
        throw error
      }
    }
  }
}
