import Foundation

extension ArcaneURLSessionTransport {
  private enum DownloadAction {
    case retry(incrementAttempt: Bool)
    case complete
  }

  private struct DownloadContext {
    let credentialGeneration: UInt64?
    let authorized: Bool
    let attempt: Int
    let destinationURL: URL
  }

  /// Downloads an authenticated response to a caller-owned destination without
  /// buffering the payload in memory. The destination is replaced atomically
  /// only after a successful response has finished downloading.
  @discardableResult
  public func downloadRaw(
    _ path: String,
    query: [URLQueryItem] = [],
    authorized: Bool = true,
    to destinationURL: URL
  ) async throws -> URL {
    var didRefresh = false
    var attempt = 1

    while true {
      var request = URLRequest(url: baseURL.appendingAPIPath(path).withQueryItems(query))
      request.httpMethod = "GET"
      request.setValue("application/octet-stream", forHTTPHeaderField: "Accept")
      let generation = try await applyAuthenticationHeaders(to: &request, authorized: authorized)
      var temporaryURL: URL?

      do {
        let (downloadedURL, response) = try await session.download(for: request)
        temporaryURL = downloadedURL
        guard let http = response as? HTTPURLResponse else {
          throw ArcaneError.transport("Download did not return an HTTP response")
        }
        let action = try await handleDownloadedFile(
          downloadedURL,
          response: http,
          didRefresh: &didRefresh,
          context: DownloadContext(
            credentialGeneration: generation,
            authorized: authorized,
            attempt: attempt,
            destinationURL: destinationURL
          )
        )
        switch action {
        case .complete:
          temporaryURL = nil
          return destinationURL
        case .retry(let incrementAttempt):
          if incrementAttempt { attempt += 1 }
          continue
        }
      } catch let error as ArcaneError {
        removeTemporaryFile(temporaryURL)
        throw error
      } catch {
        removeTemporaryFile(temporaryURL)
        if try await shouldRetryDownload(after: error, attempt: attempt) {
          attempt += 1
          continue
        }
        throw normalizedTransportError(error)
      }
    }
  }

  private func handleDownloadedFile(
    _ downloadedURL: URL,
    response: HTTPURLResponse,
    didRefresh: inout Bool,
    context: DownloadContext
  ) async throws -> DownloadAction {
    if try await refreshAuthorizationIfNeeded(
      statusCode: response.statusCode,
      authorized: context.authorized,
      didRefresh: &didRefresh
    ) {
      removeTemporaryFile(downloadedURL)
      return .retry(incrementAttempt: false)
    }

    if shouldRetry(method: "GET", statusCode: response.statusCode),
      context.attempt < retryPolicy.maxAttempts
    {
      removeTemporaryFile(downloadedURL)
      try await sleepBeforeRetry(attempt: context.attempt)
      return .retry(incrementAttempt: true)
    }

    guard (200..<300).contains(response.statusCode) else {
      let snippet = readErrorSnippet(from: downloadedURL)
      removeTemporaryFile(downloadedURL)
      if response.statusCode == 401, let credentialGeneration = context.credentialGeneration {
        try? await authManager.clear(ifCredentialGenerationMatches: credentialGeneration)
      }
      throw ArcaneError.from(
        statusCode: response.statusCode,
        data: snippet,
        headers: response.allHeaderFields,
        decoder: decoder
      )
    }

    try installDownloadedFile(from: downloadedURL, at: context.destinationURL)
    return .complete
  }

  private func shouldRetryDownload(after error: Error, attempt: Int) async throws -> Bool {
    let normalized = normalizedTransportError(error)
    guard !(normalized is CancellationError) else { throw CancellationError() }
    guard let urlError = error as? URLError,
      shouldRetry(method: "GET", error: urlError),
      attempt < retryPolicy.maxAttempts
    else { return false }
    try await sleepBeforeRetry(attempt: attempt)
    return true
  }

  private func readErrorSnippet(from url: URL) -> Data {
    guard let handle = try? FileHandle(forReadingFrom: url) else { return Data() }
    defer { try? handle.close() }
    return (try? handle.read(upToCount: 4096)) ?? Data()
  }

  private func installDownloadedFile(from temporaryURL: URL, at destinationURL: URL) throws {
    let fileManager = FileManager.default
    let directory = destinationURL.deletingLastPathComponent()
    try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    let stagingURL = directory.appendingPathComponent(
      ".\(destinationURL.lastPathComponent).arcane-download-\(UUID().uuidString)"
    )
    defer { removeTemporaryFile(stagingURL) }

    try fileManager.moveItem(at: temporaryURL, to: stagingURL)
    if fileManager.fileExists(atPath: destinationURL.path) {
      _ = try fileManager.replaceItemAt(destinationURL, withItemAt: stagingURL)
    } else {
      try fileManager.moveItem(at: stagingURL, to: destinationURL)
    }
  }

  private func removeTemporaryFile(_ url: URL?) {
    guard let url else { return }
    try? FileManager.default.removeItem(at: url)
  }
}
