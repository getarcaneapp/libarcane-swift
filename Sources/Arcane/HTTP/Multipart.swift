import Foundation

/// One file part of a multipart/form-data upload. The file is streamed from disk
/// during the upload to avoid loading large tarballs into memory.
public struct MultipartFile: Sendable {
    public var fieldName: String
    public var filename: String
    public var contentType: String
    public var fileURL: URL

    public init(fieldName: String, filename: String, contentType: String = "application/octet-stream", fileURL: URL) {
        self.fieldName = fieldName
        self.filename = filename
        self.contentType = contentType
        self.fileURL = fileURL
    }
}

/// Description of a multipart upload endpoint used to seed an `NDJSONStream`
/// when the response is a server-side progress stream rather than a single body.
struct MultipartEndpoint: Sendable {
    let path: String
    let method: String
    let query: [URLQueryItem]
    let fields: [String: String]
    let files: [MultipartFile]
}

struct PreparedMultipart {
    let url: URL
    let boundary: String
}

extension ArcaneURLSessionTransport {
    /// Performs a multipart upload and returns the response body as an async byte
    /// stream, suitable for an NDJSON progress stream. Caller is responsible for
    /// deleting the multipart tempfile once the stream finishes.
    func multipartByteStream(
        path: String,
        method: String,
        query: [URLQueryItem],
        file prepared: PreparedMultipart
    ) async throws -> (URLSession.AsyncBytes, HTTPURLResponse) {
        var request = URLRequest(url: baseURL.appendingAPIPath(path).withQueryItems(query))
        request.httpMethod = method
        request.setValue("application/x-ndjson, application/x-json-stream, application/json", forHTTPHeaderField: "Accept")
        request.setValue("multipart/form-data; boundary=\(prepared.boundary)", forHTTPHeaderField: "Content-Type")
        for (key, value) in try await authManager.authenticationHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }
        let attrs = try FileManager.default.attributesOfItem(atPath: prepared.url.path)
        if let size = attrs[.size] as? Int {
            request.setValue("\(size)", forHTTPHeaderField: "Content-Length")
        }
        request.httpBodyStream = InputStream(url: prepared.url)
        let (bytes, response) = try await session.bytes(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ArcaneError.transport("Multipart upload did not return an HTTP response")
        }
        return (bytes, http)
    }
}

extension ArcaneURLSessionTransport {
    /// Builds a multipart/form-data tempfile combining text fields and file parts.
    /// Returns the temp URL and boundary string. Caller is responsible for deleting
    /// the temp file once the upload completes.
    func makeMultipartTempFile(
        fields: [String: String],
        files: [MultipartFile]
    ) throws -> PreparedMultipart {
        let boundary = "----ArcaneSwiftBoundary\(UUID().uuidString)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("arcane-multipart-\(UUID().uuidString).bin")
        FileManager.default.createFile(atPath: tempURL.path, contents: nil)
        let handle = try FileHandle(forWritingTo: tempURL)
        defer { try? handle.close() }

        // Text fields first
        for (name, value) in fields {
            let header = "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"\r\n\r\n"
            try handle.write(contentsOf: Data(header.utf8))
            try handle.write(contentsOf: Data(value.utf8))
            try handle.write(contentsOf: Data("\r\n".utf8))
        }

        // File parts
        for file in files {
            let header = "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.filename)\"\r\nContent-Type: \(file.contentType)\r\n\r\n"
            try handle.write(contentsOf: Data(header.utf8))

            let source = try FileHandle(forReadingFrom: file.fileURL)
            defer { try? source.close() }
            while true {
                let chunk = autoreleasepool { source.availableData }
                if chunk.isEmpty { break }
                try handle.write(contentsOf: chunk)
            }

            try handle.write(contentsOf: Data("\r\n".utf8))
        }

        // Final boundary
        try handle.write(contentsOf: Data("--\(boundary)--\r\n".utf8))
        return PreparedMultipart(url: tempURL, boundary: boundary)
    }
}

