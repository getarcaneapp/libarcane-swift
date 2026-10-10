import Foundation

struct ProxyRequestSupport: Sendable {
  let baseURL: URL
  let additionalHeaders: [String: String]
  let session: (any ArcaneProxySession)?

  func prepare(_ request: inout URLRequest) async throws -> ProxyRequestDelegate {
    guard let url = request.url, contains(url) else {
      throw ArcaneError.proxyAuthenticationRequired
    }
    for (name, value) in additionalHeaders where Self.isAllowed(name: name, value: value) {
      request.setValue(value, forHTTPHeaderField: name)
    }
    if session != nil { request.httpShouldHandleCookies = false }
    let context = await session?.requestContext(for: url)
    guard context?.isValid != false else { throw CancellationError() }
    for (name, value) in context?.headers ?? [:]
    where name.caseInsensitiveCompare("Cookie") == .orderedSame
      && !value.unicodeScalars.contains(where: { $0 == "\r" || $0 == "\n" }) {
      request.setValue(value, forHTTPHeaderField: name)
    }
    return ProxyRequestDelegate(support: self, context: context, url: url)
  }

  func contains(_ url: URL) -> Bool {
    func scheme(_ url: URL) -> String? {
      switch url.scheme?.lowercased() {
      case "wss": "https"
      case "ws": "http"
      default: url.scheme?.lowercased()
      }
    }
    func port(_ url: URL) -> Int? { url.port ?? (scheme(url) == "https" ? 443 : 80) }
    guard scheme(url) == scheme(baseURL), url.host?.lowercased() == baseURL.host?.lowercased(),
      port(url) == port(baseURL)
    else { return false }
    guard url.user == nil, url.password == nil,
      !url.path.components(separatedBy: "/").contains(where: { $0 == "." || $0 == ".." })
    else { return false }
    let path = baseURL.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    return path.isEmpty || url.path == "/" + path || url.path.hasPrefix("/" + path + "/")
  }

  static func isAllowed(name: String, value: String) -> Bool {
    let token = CharacterSet(
      charactersIn: "!#$%&'*+-.^_`|~0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    )
    let lower = name.lowercased()
    return !name.isEmpty && name.unicodeScalars.allSatisfy(token.contains)
      && !value.unicodeScalars.contains(where: { $0 == "\r" || $0 == "\n" })
      && ![
        "authorization", "x-api-key", "x-step-up-token", "cookie", "host", "content-length",
        "connection", "upgrade", "transfer-encoding", "te", "trailer", "proxy-connection"
      ].contains(lower)
      && !lower.hasPrefix("x-arcane-")
  }

  func check(_ response: HTTPURLResponse, data: Data? = nil, expectsJSON: Bool = true) throws {
    guard let url = response.url, contains(url) else {
      throw ArcaneError.proxyAuthenticationRequired
    }
    let html =
      response.value(forHTTPHeaderField: "Content-Type")?.lowercased().contains("text/html") == true
    let prefix = data.flatMap { String(data: $0.prefix(512), encoding: .utf8) }?
      .trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let htmlBody = prefix?.hasPrefix("<!doctype html") == true || prefix?.hasPrefix("<html") == true
    let successful = (200..<300).contains(response.statusCode)
    if ((html || htmlBody)
      && ((successful && expectsJSON) || [401, 403, 407].contains(response.statusCode)))
      || (300..<400).contains(response.statusCode) || response.statusCode == 407
      || response.value(forHTTPHeaderField: "Proxy-Authenticate") != nil {
      throw ArcaneError.proxyAuthenticationRequired
    }
    // Non-Arcane authentication responses must not invalidate Arcane tokens.
    if [401, 403].contains(response.statusCode), let data {
      let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
      let isArcane = json?["success"] as? Bool == false
      let isProblem = json?["status"] as? Int == response.statusCode && json?["title"] is String
      if !isArcane && !isProblem { throw ArcaneError.authenticationRejected }
    }
  }
}

final class ProxyRequestDelegate: NSObject, URLSessionWebSocketDelegate, Sendable {
  let support: ProxyRequestSupport
  private struct RequestSnapshot: Sendable {
    let context: ArcaneProxyRequestContext?
    let url: URL
  }

  private actor RequestState {
    private var current: RequestSnapshot
    init(_ snapshot: RequestSnapshot) { current = snapshot }
    func snapshot() -> RequestSnapshot { current }
    func replace(_ snapshot: RequestSnapshot) { current = snapshot }
  }

  private let state: RequestState

  init(support: ProxyRequestSupport, context: ArcaneProxyRequestContext?, url: URL) {
    self.support = support
    self.state = RequestState(RequestSnapshot(context: context, url: url))
  }

  func receive(_ response: HTTPURLResponse) async {
    let snapshot = await state.snapshot()
    if let context = snapshot.context, support.contains(response.url ?? snapshot.url) {
      await support.session?.receive(
        response: response,
        for: snapshot.url,
        generation: context.generation
      )
    }
  }

  func urlSession(
    _ session: URLSession,
    webSocketTask: URLSessionWebSocketTask,
    didOpenWithProtocol protocol: String?
  ) {
    if let response = webSocketTask.response as? HTTPURLResponse {
      Task { await receive(response) }
    }
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    if task is URLSessionWebSocketTask, error != nil,
      let response = task.response as? HTTPURLResponse {
      Task { await receive(response) }
    }
  }

  func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse,
    newRequest request: URLRequest,
    completionHandler: @escaping @Sendable (URLRequest?) -> Void
  ) {
    // Keeping the original response makes an out-of-scope redirect a proxy gate,
    // without ever sending credentials to its destination.
    guard let destination = request.url, support.contains(destination) else {
      completionHandler(nil)
      return
    }
    Task {
      await receive(response)
      var redirected = request
      do {
        let next = try await support.prepare(&redirected)
        await state.replace(await next.state.snapshot())
        completionHandler(redirected)
      } catch {
        completionHandler(nil)
      }
    }
  }
}
