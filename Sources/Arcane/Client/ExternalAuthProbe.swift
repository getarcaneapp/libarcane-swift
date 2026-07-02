import Foundation

/// Outcome of probing a server for a ForwardAuth-style reverse proxy (e.g.
/// Traefik + Authelia) sitting in front of Arcane.
public enum ExternalAuthDetection: Sendable, Equatable {
    /// No proxy interception — the Arcane API answered directly.
    case none
    /// The server is fronted by an external auth provider. `portalURL` is the
    /// login portal to open (from a redirect `Location`) when it could be
    /// inferred; `nil` when the proxy answered inline (401/403/200 HTML) with no
    /// redirect to follow.
    case external(portalURL: URL?)
    /// Could not decide (network error / timeout / ambiguous status). Never
    /// treated as "proxy present" — a transient failure must not lock a user out
    /// of a plain server.
    case inconclusive
}

extension ArcaneClient {
    /// Probes whether this server sits behind a reverse-proxy external auth
    /// provider (Traefik ForwardAuth / Authelia).
    ///
    /// The SDK maps a bare proxy 401 to `.externalAuth` on ordinary requests, but
    /// a redirect-based proxy (302 → portal HTML → 200) is invisible to that
    /// path. This probe hits the public-settings endpoint with redirects
    /// **blocked** and inspects the raw response, so both proxy shapes are
    /// detectable. It shares the client's cookie jar (so an already-captured
    /// session satisfies the probe) and its `additionalHeaders`.
    public func detectExternalAuth() async -> ExternalAuthDetection {
        await ExternalAuthProbe.probe(
            baseURL: configuration.baseURL,
            additionalHeaders: configuration.additionalHeaders,
            cookieStorage: configuration.urlSession.configuration.httpCookieStorage
        )
    }
}

enum ExternalAuthProbe {
    /// Total time budget for the probe. Kept short so failure paths stay snappy.
    private static let timeout: TimeInterval = 10

    static func probe(
        baseURL: URL,
        additionalHeaders: [String: String],
        cookieStorage: HTTPCookieStorage?
    ) async -> ExternalAuthDetection {
        let url = baseURL.appendingAPIPath("environments/0/settings/public")

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCache = nil
        // Share the caller's cookie jar so an already-captured provider session
        // satisfies the probe — it doubles as a "is the proxy cookie still good?"
        // check.
        configuration.httpCookieStorage = cookieStorage ?? .shared
        configuration.httpShouldSetCookies = true
        if !additionalHeaders.isEmpty {
            configuration.httpAdditionalHeaders = additionalHeaders
        }

        let delegate = RedirectBlockingDelegate()
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = timeout

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return .inconclusive
            }
            return classify(http: http, data: data, serverURL: baseURL)
        } catch {
            // URLError / timeout / cancellation — never claim a proxy on failure.
            return .inconclusive
        }
    }

    private static func classify(http: HTTPURLResponse, data: Data, serverURL: URL) -> ExternalAuthDetection {
        let status = http.statusCode

        // A blocked redirect surfaces as the 3xx response itself.
        if (300..<400).contains(status) {
            return classifyRedirect(http: http, serverURL: serverURL)
        }

        let contentType = (http.value(forHTTPHeaderField: "Content-Type") ?? "").lowercased()
        let isHTML = contentType.contains("text/html")
        let looksJSON = contentType.contains("json") || (try? JSONSerialization.jsonObject(with: data)) != nil

        switch status {
        case 200..<300:
            // The Arcane public settings endpoint returns JSON. HTML (or any
            // non-JSON) here is a portal page served with a 200 by the proxy.
            return (looksJSON && !isHTML) ? .none : .external(portalURL: nil)
        case 401, 403:
            // A proxy intercept typically answers with an HTML portal / plain
            // body. A JSON error body is more likely a genuine Arcane response,
            // so stay inconclusive rather than mislabeling it.
            return (isHTML || !looksJSON) ? .external(portalURL: nil) : .inconclusive
        default:
            return .inconclusive
        }
    }

    private static func classifyRedirect(http: HTTPURLResponse, serverURL: URL) -> ExternalAuthDetection {
        let location = http.value(forHTTPHeaderField: "Location")
        let locationURL = location.flatMap { URL(string: $0, relativeTo: serverURL)?.absoluteURL }
        let serverHost = serverURL.host?.lowercased()
        let locationHost = locationURL?.host?.lowercased()

        // Redirect to a different host — an external portal (e.g. auth.example.com).
        if let locationHost, locationHost != serverHost {
            return .external(portalURL: locationURL)
        }

        // Same-host redirect away from the API surface — a same-domain portal.
        let path = locationURL?.path ?? location ?? ""
        if !path.hasPrefix("/api") {
            return .external(portalURL: locationURL)
        }

        // Same-host redirect that stays under /api is not a recognizable portal.
        return .inconclusive
    }
}

/// Blocks transparent URLSession redirect-following for the probe session so a
/// ForwardAuth 302 to the provider portal is observable instead of silently
/// followed to a 200 HTML page.
private final class RedirectBlockingDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}
