import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2
import SwiftProtobuf

/// High-level mobile gRPC client. Holds a long-lived HTTP/2 transport that
/// can be reused across calls for a given (server URL, device token) pair.
///
/// Usage:
/// ```swift
/// let client = ArcaneGRPCClient(configuration: .init(
///     serverURL: URL(string: "https://arcane.example.com")!,
///     deviceToken: "arc_..."
/// ))
/// let info = try await client.getServerInfo()
/// ```
public actor ArcaneGRPCClient {
    public struct Configuration: Sendable {
        public let serverURL: URL
        public let deviceToken: String?
        public let allowInsecure: Bool

        public init(serverURL: URL, deviceToken: String? = nil, allowInsecure: Bool = false) {
            self.serverURL = serverURL
            self.deviceToken = deviceToken
            self.allowInsecure = allowInsecure
        }
    }

    private let configuration: Configuration
    private var clientTask: Task<Void, Never>?
    private var grpcClient: GRPCClient<HTTP2ClientTransport.Posix>?

    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    deinit {
        clientTask?.cancel()
    }

    // MARK: - Lifecycle

    private func ensureClient() async throws -> GRPCClient<HTTP2ClientTransport.Posix> {
        if let existing = grpcClient { return existing }

        let host = configuration.serverURL.host ?? "localhost"
        let port = configuration.serverURL.port ?? defaultPort()

        let security: HTTP2ClientTransport.Posix.TransportSecurity =
            (configuration.serverURL.scheme?.lowercased() == "https") ? .tls : .plaintext

        let transport = try HTTP2ClientTransport.Posix(
            target: .dns(host: host, port: port),
            transportSecurity: security
        )

        let client = GRPCClient(transport: transport)
        let task: Task<Void, Never> = Task { [client] in
            do {
                try await client.runConnections()
            } catch {
                // Connection loop exits when the actor is torn down or the
                // peer disconnects; surface as a debug log only.
            }
        }
        self.grpcClient = client
        self.clientTask = task
        return client
    }

    private func defaultPort() -> Int {
        let scheme = configuration.serverURL.scheme?.lowercased() ?? "https"
        return scheme == "https" ? 443 : 80
    }

    private func authMetadata() -> Metadata {
        var md = Metadata()
        if let token = configuration.deviceToken, !token.isEmpty {
            md.replaceOrAddString(token, forKey: "x-api-key")
        }
        return md
    }

    // MARK: - PairingService (unauthenticated)

    /// RedeemCode handshake. No device token required.
    public func redeemPairingCode(
        code: String,
        deviceID: String,
        deviceName: String,
        appVersion: String,
        osVersion: String,
        deviceModel: String
    ) async throws -> Mobile_V1_RedeemCodeResponse {
        let client = try await ensureClient()
        let pairing = Mobile_V1_PairingService.Client(wrapping: client)
        var request = Mobile_V1_RedeemCodeRequest()
        request.code = code
        request.deviceID = deviceID
        request.deviceName = deviceName
        request.appVersion = appVersion
        request.osVersion = osVersion
        request.deviceModel = deviceModel
        return try await pairing.redeemCode(request)
    }

    // MARK: - MobileService (authenticated)

    public func getServerInfo() async throws -> Mobile_V1_GetServerInfoResponse {
        try await unaryAuthenticated { service in
            try await service.getServerInfo(.init(), metadata: self.authMetadata())
        }
    }

    public func listContainers(
        environmentID: String = "0",
        includeAll: Bool = true,
        search: String = "",
        limit: Int32 = 100,
        offset: Int32 = 0
    ) async throws -> Mobile_V1_ListContainersResponse {
        var req = Mobile_V1_ListContainersRequest()
        req.environmentID = environmentID
        req.includeAll = includeAll
        req.search = search
        req.limit = limit
        req.offset = offset
        let request = req
        let md = authMetadata()
        return try await unaryAuthenticated { service in
            try await service.listContainers(request, metadata: md)
        }
    }

    public func getCurrentDevice() async throws -> Mobile_V1_GetCurrentDeviceResponse {
        let md = authMetadata()
        return try await unaryAuthenticated { service in
            try await service.getCurrentDevice(.init(), metadata: md)
        }
    }

    public func revokeCurrentDevice() async throws -> Mobile_V1_RevokeCurrentDeviceResponse {
        let md = authMetadata()
        return try await unaryAuthenticated { service in
            try await service.revokeCurrentDevice(.init(), metadata: md)
        }
    }

    private func unaryAuthenticated<Result: Sendable>(
        _ perform: @Sendable (Mobile_V1_MobileService.Client<HTTP2ClientTransport.Posix>) async throws -> Result
    ) async throws -> Result {
        guard configuration.deviceToken != nil else {
            throw ArcaneGRPCError.missingDeviceToken
        }
        let client = try await ensureClient()
        let service = Mobile_V1_MobileService.Client(wrapping: client)
        return try await perform(service)
    }
}

public enum ArcaneGRPCError: Error, Sendable {
    case missingDeviceToken
    case invalidServerURL
    case transportFailed(String)
}
