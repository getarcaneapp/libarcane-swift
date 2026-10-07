import Foundation
import Testing

@testable import Arcane

@Suite("Proxy authentication")
struct ProxyAuthenticationTests {
  private let baseURL = URL(string: "https://arcane.example.com/instance")!

  @Test func debugDescriptionsRedactCredentials() {
    let context = ArcaneProxyRequestContext(headers: ["Cookie": "secret-cookie"], generation: 1)
    let configuration = ArcaneClient.Configuration(
      baseURL: baseURL, additionalHeaders: ["X-Test": "secret-header"])
    #expect(!String(reflecting: context).contains("secret-cookie"))
    #expect(!String(reflecting: configuration).contains("secret-header"))
  }

  @Test func invalidatedCookieContextCancelsBeforeSendingHeaders() async throws {
    let support = ProxyRequestSupport(
      baseURL: baseURL, additionalHeaders: ["X-Proxy-Token": "secret"],
      session: InvalidProxySession())
    await #expect(throws: CancellationError.self) {
      var request = URLRequest(url: baseURL.appendingPathComponent("api/auth"))
      _ = try await support.prepare(&request)
    }
  }

  @Test func validatesCredentialScope() {
    let support = ProxyRequestSupport(baseURL: baseURL, additionalHeaders: [:], session: nil)
    #expect(support.contains(URL(string: "https://arcane.example.com/instance/api/auth")!))
    #expect(support.contains(URL(string: "wss://arcane.example.com/instance/api/logs")!))
    #expect(!support.contains(URL(string: "https://arcane.example.com/instance-other/api")!))
    #expect(!support.contains(URL(string: "https://other.example.com/instance/api")!))
    #expect(!support.contains(URL(string: "http://arcane.example.com/instance/api")!))
    #expect(!support.contains(URL(string: "https://arcane.example.com:8443/instance/api")!))
    #expect(!support.contains(URL(string: "https://arcane.example.com/instance/%2e%2e/other")!))
  }

  @Test func rejectsReservedHeadersAndInjection() {
    for name in [
      "Authorization", "X-API-Key", "X-Step-Up-Token", "X-Arcane-Batch-ID", "Cookie", "Host",
      "Upgrade",
    ] {
      #expect(!ProxyRequestSupport.isAllowed(name: name, value: "secret"))
    }
    #expect(ProxyRequestSupport.isAllowed(name: "Proxy-Authorization", value: "Basic abc"))
    #expect(ProxyRequestSupport.isAllowed(name: "X-Proxy-Token", value: "token"))
    #expect(!ProxyRequestSupport.isAllowed(name: "Bad Name", value: "token"))
    #expect(!ProxyRequestSupport.isAllowed(name: "X-Test", value: "value\r\nInjected: true"))
  }

  @Test func usesGenerationBoundCookieContext() async throws {
    let session = TestProxySession()
    let support = ProxyRequestSupport(
      baseURL: baseURL, additionalHeaders: ["X-Proxy-Token": "secret"], session: session)
    var request = URLRequest(url: baseURL.appendingPathComponent("api/auth"))
    let delegate = try await support.prepare(&request)
    #expect(request.value(forHTTPHeaderField: "X-Proxy-Token") == "secret")
    #expect(request.value(forHTTPHeaderField: "Cookie") == "proxy=session")
    #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    let response = try #require(
      HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: [:]))
    await delegate.receive(response)
    #expect(await session.receivedGenerations == [42])
  }

  @Test func recognizesProxyPortalAndAmbiguousRejection() throws {
    let support = ProxyRequestSupport(baseURL: baseURL, additionalHeaders: [:], session: nil)
    let url = baseURL.appendingPathComponent("api/auth")
    for status in [200, 401, 403] {
      let html = try #require(
        HTTPURLResponse(
          url: url, statusCode: status, httpVersion: nil,
          headerFields: ["Content-Type": "text/html; charset=utf-8"]))
      #expect(throws: ArcaneError.proxyAuthenticationRequired) {
        try support.check(html, data: Data())
      }
    }
    let portalWithoutContentType = try #require(
      HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: [:]))
    #expect(throws: ArcaneError.proxyAuthenticationRequired) {
      try support.check(
        portalWithoutContentType, data: Data("  <!DOCTYPE html><html>Sign in</html>".utf8))
    }
    let gatewayFailure = try #require(
      HTTPURLResponse(
        url: url, statusCode: 502, httpVersion: nil,
        headerFields: ["Content-Type": "text/html"]))
    try support.check(gatewayFailure, data: Data("<html>Bad gateway</html>".utf8))
    let unauthorized = try #require(
      HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: [:]))
    #expect(throws: ArcaneError.authenticationRejected) {
      try support.check(unauthorized, data: Data("Unauthorized".utf8))
    }
    try support.check(
      unauthorized, data: Data(#"{"success":false,"error":"Invalid credentials"}"#.utf8))
    try support.check(unauthorized, data: Data(#"{"status":401,"title":"Unauthorized"}"#.utf8))
  }

  @Test func appliesCredentialsToNativeRequestCategories() async throws {
    let mock = MockURLProtocolSession()
    let session = TestProxySession()
    let client = ArcaneClient(
      configuration: .init(
        baseURL: baseURL, urlSession: mock.session(),
        additionalHeaders: ["X-Proxy-Token": "secret"], proxySession: session))
    await mock.setHandler { request in
      #expect(request.value(forHTTPHeaderField: "X-Proxy-Token") == "secret")
      #expect(request.value(forHTTPHeaderField: "Cookie") == "proxy=session")
      return (
        try #require(
          HTTPURLResponse(
            url: request.url!, statusCode: 200, httpVersion: nil,
            headerFields: ["Content-Type": "application/json"])),
        Data(#"{"success":true,"data":"ok"}"#.utf8)
      )
    }
    _ = try await client.transport.rawRequest(
      "auth/login", body: Optional<String>.none, authorized: false)
    _ = try await client.transport.rawDataRequest("upload", body: Data("body".utf8))
    let result: String = try await client.transport.multipartUpload(
      "upload", fields: ["name": "value"], files: [])
    #expect(result == "ok")
    let (bytes, _) = try await client.transport.byteStream(path: "stream")
    for try await _ in bytes {}
    let destination = FileManager.default.temporaryDirectory.appendingPathComponent(
      UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: destination) }
    _ = try await client.transport.downloadRaw("download", to: destination)
    #expect(try Data(contentsOf: destination) == Data(#"{"success":true,"data":"ok"}"#.utf8))
    let multipart = try client.transport.makeMultipartTempFile(fields: ["name": "value"], files: [])
    defer { try? FileManager.default.removeItem(at: multipart.url) }
    let (uploadBytes, _) = try await client.transport.multipartByteStream(
      path: "upload-stream", method: "POST", query: [], file: multipart)
    for try await _ in uploadBytes {}
    let socket = try await client.transport.websocketRequest(path: "logs")
    #expect(socket.value(forHTTPHeaderField: "X-Proxy-Token") == "secret")
    #expect(socket.value(forHTTPHeaderField: "Cookie") == "proxy=session")
    #expect(await session.receivedGenerations.count == 6)
  }

  @Test func successfulHTMLFilesRemainDownloadable() async throws {
    let mock = MockURLProtocolSession()
    let client = ArcaneClient(configuration: .init(baseURL: baseURL, urlSession: mock.session()))
    let html = Data("<!DOCTYPE html><html>Volume file</html>".utf8)
    await mock.setHandler { request in
      (
        try #require(
          HTTPURLResponse(
            url: request.url!, statusCode: 200, httpVersion: nil,
            headerFields: ["Content-Type": "text/html"])), html
      )
    }
    #expect(try await client.transport.downloadRaw("volume/file") == html)
    #expect(
      try await client.transport.rawDataRequest("volume/file", method: "GET", body: nil) == html)
    let destination = FileManager.default.temporaryDirectory.appendingPathComponent(
      UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: destination) }
    _ = try await client.transport.downloadRaw("volume/file", to: destination)
    #expect(try Data(contentsOf: destination) == html)
    await #expect(throws: ArcaneError.proxyAuthenticationRequired) {
      try await client.transport.rawRequest(
        "settings/public", body: Optional<String>.none, authorized: false)
    }
  }

  @Test func refreshIncludesCredentialsAndProxyRejectionRetainsTokens() async throws {
    let mock = MockURLProtocolSession()
    let session = TestProxySession()
    let tokens = TokenPair(
      accessToken: "access", refreshToken: "refresh", expiresAt: .distantFuture)
    let store = InMemoryTokenStore(tokens: tokens)
    let client = ArcaneClient(
      configuration: .init(
        baseURL: baseURL, tokenStore: store, urlSession: mock.session(),
        additionalHeaders: ["X-Proxy-Token": "secret"], proxySession: session))
    await mock.setHandler { request in
      #expect(request.value(forHTTPHeaderField: "X-Proxy-Token") == "secret")
      #expect(request.value(forHTTPHeaderField: "Cookie") == "proxy=session")
      return (
        try #require(
          HTTPURLResponse(
            url: request.url!, statusCode: 401, httpVersion: nil,
            headerFields: ["Content-Type": "text/html"])), Data("<html>Sign in</html>".utf8)
      )
    }
    await #expect(throws: ArcaneError.proxyAuthenticationRequired) {
      try await client.authManager.refreshTokens()
    }
    #expect(try await store.loadTokens() == tokens)
    await #expect(throws: ArcaneError.proxyAuthenticationRequired) {
      try await client.transport.rawRequest("containers", body: Optional<String>.none)
    }
    #expect(try await store.loadTokens() == tokens)
    #expect(await mock.requestCount() == 2)
  }

  @Test func redirectsUseFreshCookieSnapshotForFinalResponse() async throws {
    let session = RedirectProxySession()
    let support = ProxyRequestSupport(baseURL: baseURL, additionalHeaders: [:], session: session)
    var request = URLRequest(url: baseURL.appendingPathComponent("api/from"))
    let delegate = try await support.prepare(&request)
    let redirect = try #require(
      HTTPURLResponse(url: request.url!, statusCode: 302, httpVersion: nil, headerFields: [:]))
    let target = baseURL.appendingPathComponent("api/to")
    let task = URLSession.shared.dataTask(with: request)
    let forwarded: URLRequest? = await withCheckedContinuation { continuation in
      delegate.urlSession(
        URLSession.shared, task: task, willPerformHTTPRedirection: redirect,
        newRequest: URLRequest(url: target)
      ) { continuation.resume(returning: $0) }
    }
    #expect(forwarded?.value(forHTTPHeaderField: "Cookie") == "proxy=2")
    await delegate.receive(
      try #require(
        HTTPURLResponse(url: target, statusCode: 200, httpVersion: nil, headerFields: [:])))
    #expect(await session.receivedGenerations == [1, 2])
    #expect(await session.receivedURLs == [request.url!, target])
  }

  @Test func rejectsCrossOriginRedirectBeforeSendingCredentials() async throws {
    let support = ProxyRequestSupport(
      baseURL: baseURL, additionalHeaders: ["X-Proxy-Token": "secret"], session: nil)
    var request = URLRequest(url: baseURL.appendingPathComponent("api/auth"))
    let delegate = try await support.prepare(&request)
    let response = try #require(
      HTTPURLResponse(url: request.url!, statusCode: 302, httpVersion: nil, headerFields: [:]))
    let task = URLSession.shared.dataTask(with: request)
    let forwarded: URLRequest? = await withCheckedContinuation { continuation in
      delegate.urlSession(
        URLSession.shared, task: task, willPerformHTTPRedirection: response,
        newRequest: URLRequest(url: URL(string: "https://idp.example.com/login")!)
      ) {
        continuation.resume(returning: $0)
      }
    }
    #expect(forwarded == nil)
  }
}

private actor TestProxySession: ArcaneProxySession {
  var receivedGenerations: [UInt64] = []
  func requestContext(for url: URL) -> ArcaneProxyRequestContext {
    ArcaneProxyRequestContext(
      headers: ["Cookie": "proxy=session", "Authorization": "must-not-override"], generation: 42)
  }
  func receive(response: HTTPURLResponse, for url: URL, generation: UInt64) {
    receivedGenerations.append(generation)
  }
}

private struct InvalidProxySession: ArcaneProxySession {
  func requestContext(for url: URL) async -> ArcaneProxyRequestContext {
    ArcaneProxyRequestContext(headers: [:], generation: 1, isValid: false)
  }
  func receive(response: HTTPURLResponse, for url: URL, generation: UInt64) async {
    Issue.record("An invalidated proxy session must not receive a response.")
  }
}

private actor RedirectProxySession: ArcaneProxySession {
  private var nextGeneration: UInt64 = 0
  var receivedGenerations: [UInt64] = []
  var receivedURLs: [URL] = []
  func requestContext(for url: URL) -> ArcaneProxyRequestContext {
    nextGeneration &+= 1
    return ArcaneProxyRequestContext(
      headers: ["Cookie": "proxy=\(nextGeneration)"], generation: nextGeneration)
  }
  func receive(response: HTTPURLResponse, for url: URL, generation: UInt64) {
    receivedGenerations.append(generation)
    receivedURLs.append(url)
  }
}
