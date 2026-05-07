import ArcaneAPI
import Foundation
import HTTPTypes
import OpenAPIRuntime
import OpenAPIURLSession

extension ArcaneClient {
    public var generated: ArcaneAPI.Client {
        ArcaneAPI.Client(
            serverURL: configuration.baseURL.appendingAPIPath(""),
            transport: URLSessionTransport(configuration: .init(session: configuration.urlSession)),
            middlewares: [ArcaneAuthMiddleware(authManager: authManager)]
        )
    }
}

public struct ArcaneAuthMiddleware: ClientMiddleware {
    private let authManager: AuthManager

    public init(authManager: AuthManager) {
        self.authManager = authManager
    }

    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var authorizedRequest = request
        for (name, value) in try await authManager.authenticationHeaders() {
            guard let headerName = HTTPField.Name(name) else {
                continue
            }
            authorizedRequest.headerFields[headerName] = value
        }

        let first = try await next(authorizedRequest, body, baseURL)
        guard first.0.status.code == 401, try await authManager.hasRefreshCredential() else {
            return first
        }

        _ = try await authManager.refreshTokens()
        var retryRequest = request
        for (name, value) in try await authManager.authenticationHeaders() {
            guard let headerName = HTTPField.Name(name) else {
                continue
            }
            retryRequest.headerFields[headerName] = value
        }
        let second = try await next(retryRequest, body, baseURL)
        if second.0.status.code == 401 {
            try? await authManager.clear()
        }
        return second
    }
}
