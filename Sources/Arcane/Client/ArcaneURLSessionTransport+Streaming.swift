import Foundation

extension ArcaneURLSessionTransport {
  /// Returns the bytes of an HTTP response as an async sequence, plus the response
  /// metadata. Used by NDJSON streams and binary downloads. The caller is responsible
  /// for checking `http.statusCode` and consuming the bytes — this method does not
  /// validate the response status.
  @concurrent
  public func byteStream(
    path: String,
    method: String = "GET",
    query: [URLQueryItem] = [],
    body: Data? = nil,
    contentType: String? = nil,
    accept: String = "application/x-ndjson, application/x-json-stream, application/json",
    authorized: Bool = true,
    options: ArcaneRequestOptions? = nil
  ) async throws -> (URLSession.AsyncBytes, HTTPURLResponse) {
    var didRefresh = false
    let requestOptions = resolvedRequestOptions(options)
    while true {
      var request = URLRequest(url: baseURL.appendingAPIPath(path).withQueryItems(query))
      request.httpMethod = method
      request.setValue(accept, forHTTPHeaderField: "Accept")
      applyRequestOptions(to: &request, options: requestOptions)
      let generation = try await applyAuthenticationHeaders(to: &request, authorized: authorized)
      if let body {
        if let contentType {
          request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        request.httpBody = body
      }
      let proxyDelegate = try await proxySupport.prepare(&request)
      let (bytes, response): (URLSession.AsyncBytes, URLResponse)
      do {
        (bytes, response) = try await session.bytes(for: request, delegate: proxyDelegate)
      } catch {
        throw normalizedTransportError(error)
      }
      guard let http = response as? HTTPURLResponse else {
        throw ArcaneError.transport("Request did not return an HTTP response")
      }
      await proxyDelegate.receive(http)
      try await checkStreamResponse(http, bytes: bytes, expectsJSON: accept.lowercased().contains("json"))
      if try await refreshAuthorizationIfNeeded(
        statusCode: http.statusCode,
        authorized: authorized,
        didRefresh: &didRefresh
      ) {
        continue
      }
      if http.statusCode == 401, let generation {
        try? await authManager.clear(ifCredentialGenerationMatches: generation)
      }
      return (bytes, http)
    }
  }

  /// Uploads a multipart/form-data request from a tempfile (streamed from disk to
  /// avoid loading large files into memory). The response is decoded as the
  /// standard `APIResponse<T>` envelope.
  @concurrent
  public func multipartUpload<T: Decodable & Sendable>(
    _ path: String,
    method: String = "POST",
    query: [URLQueryItem] = [],
    fields: [String: String] = [:],
    files: [MultipartFile],
    options: ArcaneRequestOptions? = nil
  ) async throws -> T {
    let prepared = try makeMultipartTempFile(fields: fields, files: files)
    defer { try? FileManager.default.removeItem(at: prepared.url) }

    var didRefresh = false
    let requestOptions = resolvedRequestOptions(options)
    while true {
      let preparedRequest = try await makeMultipartRequest(
        path: path,
        method: method,
        query: query,
        prepared: prepared,
        accept: "application/json",
        options: requestOptions
      )
      var request = preparedRequest.request
      let proxyDelegate = try await proxySupport.prepare(&request)
      let (data, response): (Data, URLResponse)
      do {
        (data, response) = try await session.upload(
          for: request,
          fromFile: prepared.url,
          delegate: proxyDelegate
        )
      } catch {
        throw normalizedTransportError(error)
      }
      guard let http = response as? HTTPURLResponse else {
        throw ArcaneError.transport("Upload did not return an HTTP response")
      }
      await proxyDelegate.receive(http)
      try proxySupport.check(http, data: data)
      if try await refreshAuthorizationIfNeeded(
        statusCode: http.statusCode,
        authorized: true,
        didRefresh: &didRefresh
      ) {
        continue
      }
      guard (200..<300).contains(http.statusCode) else {
        if http.statusCode == 401, let generation = preparedRequest.credentialGeneration {
          try? await authManager.clear(ifCredentialGenerationMatches: generation)
        }
        throw ArcaneError.from(
          statusCode: http.statusCode, data: data, headers: http.allHeaderFields, decoder: decoder)
      }
      do {
        return try decoder.decode(APIResponse<T>.self, from: data).data
      } catch {
        throw ArcaneError.decoding(String(describing: error))
      }
    }
  }

  /// Uploads a multipart/form-data request to an endpoint that returns NDJSON.
  public func multipartUploadStream<Element: Decodable & Sendable>(
    _ path: String,
    method: String = "POST",
    query: [URLQueryItem] = [],
    fields: [String: String] = [:],
    files: [MultipartFile],
    options: ArcaneRequestOptions? = nil
  ) -> NDJSONStream<Element> {
    // The actual upload and streaming happen lazily inside the AsyncSequence's
    // iterator so the caller can `for try await` directly. The body is the
    // assembled multipart tempfile; the stream owns the tempfile lifecycle.
    let endpoint = MultipartEndpoint(
      path: path, method: method, query: query, fields: fields, files: files)
    let streamTransport = options.map(withRequestOptions) ?? self
    return NDJSONStream(transport: streamTransport, multipart: endpoint)
  }

}
