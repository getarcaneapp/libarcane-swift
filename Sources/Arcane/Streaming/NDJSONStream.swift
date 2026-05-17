import Foundation

/// An `AsyncSequence` that consumes newline-delimited JSON (NDJSON / x-json-stream)
/// from a backend endpoint and yields decoded values. Used by streaming endpoints
/// like image pull/build, project up/down/pull/build, and image upload.
public struct NDJSONStream<Element: Decodable & Sendable>: AsyncSequence, Sendable {
    public typealias AsyncIterator = AsyncThrowingStream<Element, Error>.Iterator

    enum Source: Sendable {
        case body(method: String, body: Data?, contentType: String?, query: [URLQueryItem])
        case multipart(MultipartEndpoint)
    }

    private let transport: ArcaneURLSessionTransport
    private let path: String
    private let source: Source

    init(
        transport: ArcaneURLSessionTransport,
        path: String,
        method: String,
        body: Data?,
        contentType: String? = "application/json",
        query: [URLQueryItem] = []
    ) {
        self.transport = transport
        self.path = path
        self.source = .body(method: method, body: body, contentType: contentType, query: query)
    }

    init(transport: ArcaneURLSessionTransport, multipart endpoint: MultipartEndpoint) {
        self.transport = transport
        self.path = endpoint.path
        self.source = .multipart(endpoint)
    }

    public func makeAsyncIterator() -> AsyncIterator {
        let transport = self.transport
        let path = self.path
        let source = self.source
        return AsyncThrowingStream<Element, Error> { continuation in
            let task = Task {
                do {
                    let (bytes, http, cleanup) = try await Self.openByteStream(
                        transport: transport,
                        path: path,
                        source: source
                    )
                    defer { cleanup() }

                    guard (200..<300).contains(http.statusCode) else {
                        var snippet = Data()
                        for try await byte in bytes {
                            snippet.append(byte)
                            if snippet.count > 4096 { break }
                        }
                        throw ArcaneError.from(
                            statusCode: http.statusCode,
                            data: snippet,
                            headers: http.allHeaderFields,
                            decoder: ArcaneJSON.makeDecoder()
                        )
                    }
                    let decoder = ArcaneJSON.makeDecoder()
                    for try await line in bytes.lines {
                        if Task.isCancelled { break }
                        let trimmed = line.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty,
                              let data = trimmed.data(using: .utf8) else { continue }
                        let looksLikeJSON = trimmed.hasPrefix("{") || trimmed.hasPrefix("[")
                        do {
                            let element = try decoder.decode(Element.self, from: data)
                            continuation.yield(element)
                        } catch {
                            // Lines that don't look like JSON (heartbeats, comments,
                            // status text) are intentionally skipped. Lines that
                            // *do* look like JSON but fail to decode indicate a
                            // schema mismatch the caller needs to know about.
                            if looksLikeJSON {
                                throw ArcaneError.decoding(String(describing: error))
                            }
                            continue
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }.makeAsyncIterator()
    }

    private static func openByteStream(
        transport: ArcaneURLSessionTransport,
        path: String,
        source: Source
    ) async throws -> (URLSession.AsyncBytes, HTTPURLResponse, @Sendable () -> Void) {
        switch source {
        case let .body(method, body, contentType, query):
            let (bytes, http) = try await transport.byteStream(
                path: path,
                method: method,
                query: query,
                body: body,
                contentType: contentType
            )
            return (bytes, http, {})
        case let .multipart(endpoint):
            let prepared = try transport.makeMultipartTempFile(fields: endpoint.fields, files: endpoint.files)
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
                return (bytes, http, cleanup)
            } catch {
                cleanup()
                throw error
            }
        }
    }
}
