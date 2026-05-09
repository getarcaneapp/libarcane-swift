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

    internal let configuration: Configuration
    private var clientTask: Task<Void, Never>?
    private var grpcClient: GRPCClient<HTTP2ClientTransport.Posix>?

    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    deinit {
        clientTask?.cancel()
    }

    // MARK: - Lifecycle

    internal func ensureClient() async throws -> GRPCClient<HTTP2ClientTransport.Posix> {
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

    internal func authMetadata() -> Metadata {
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

    /// Returns containers for the requested environment. The `containersJson`
    /// field on the response is a JSON-encoded array of `ContainerSummary`
    /// (the existing libarcane-swift Codable type) — decode with
    /// `JSONDecoder().decode([ContainerSummary].self, from: response.containersJson)`.
    public func listContainers(
        environmentID: String = "0",
        includeAll: Bool = true,
        includeInternal: Bool = false,
        search: String = "",
        limit: Int32 = 0,
        offset: Int32 = 0,
        groupBy: String = ""
    ) async throws -> Mobile_V1_ListContainersResponse {
        var req = Mobile_V1_ListContainersRequest()
        req.environmentID = environmentID
        req.includeAll = includeAll
        req.includeInternal = includeInternal
        req.search = search
        req.limit = limit
        req.offset = offset
        req.groupBy = groupBy
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

    // MARK: - System / version

    public func getDockerInfo(environmentID: String = "0") async throws -> Data {
        var req = Mobile_V1_GetDockerInfoRequest()
        req.environmentID = environmentID
        let request = req
        let md = authMetadata()
        let response = try await unaryAuthenticated { service in
            try await service.getDockerInfo(request, metadata: md)
        }
        return response.infoJson
    }

    public func getAppVersion() async throws -> Data {
        let md = authMetadata()
        let response = try await unaryAuthenticated { service in
            try await service.getAppVersion(.init(), metadata: md)
        }
        return response.infoJson
    }

    // MARK: - Containers

    public func inspectContainer(environmentID: String = "0", id: String) async throws -> Data {
        var req = Mobile_V1_InspectContainerRequest()
        req.environmentID = environmentID
        req.id = id
        let request = req
        let md = authMetadata()
        let response = try await unaryAuthenticated { service in
            try await service.inspectContainer(request, metadata: md)
        }
        return response.detailsJson
    }

    public func startContainer(environmentID: String = "0", id: String) async throws {
        try await runContainerAction(environmentID: environmentID, id: id, kind: .start)
    }
    public func stopContainer(environmentID: String = "0", id: String) async throws {
        try await runContainerAction(environmentID: environmentID, id: id, kind: .stop)
    }
    public func restartContainer(environmentID: String = "0", id: String) async throws {
        try await runContainerAction(environmentID: environmentID, id: id, kind: .restart)
    }
    public func redeployContainer(environmentID: String = "0", id: String) async throws {
        try await runContainerAction(environmentID: environmentID, id: id, kind: .redeploy)
    }

    public func deleteContainer(environmentID: String = "0", id: String, force: Bool = false, removeVolumes: Bool = false) async throws {
        var req = Mobile_V1_DeleteContainerRequest()
        req.environmentID = environmentID
        req.id = id
        req.force = force
        req.removeVolumes = removeVolumes
        let request = req
        let md = authMetadata()
        _ = try await unaryAuthenticated { service in
            try await service.deleteContainer(request, metadata: md)
        }
    }

    public func pruneContainers(environmentID: String = "0") async throws -> Data {
        var req = Mobile_V1_PruneContainersRequest()
        req.environmentID = environmentID
        let request = req
        let md = authMetadata()
        let response = try await unaryAuthenticated { service in
            try await service.pruneContainers(request, metadata: md)
        }
        return response.reportJson
    }

    // MARK: - Volumes

    public func listVolumes(environmentID: String = "0") async throws -> Data {
        var req = Mobile_V1_ListVolumesRequest()
        req.environmentID = environmentID
        let request = req
        let md = authMetadata()
        let response = try await unaryAuthenticated { service in
            try await service.listVolumes(request, metadata: md)
        }
        return response.volumesJson
    }

    public func getVolumeSizes(environmentID: String = "0") async throws -> [Mobile_V1_VolumeSize] {
        var req = Mobile_V1_GetVolumeSizesRequest()
        req.environmentID = environmentID
        let request = req
        let md = authMetadata()
        let response = try await unaryAuthenticated { service in
            try await service.getVolumeSizes(request, metadata: md)
        }
        return response.sizes
    }

    public func createVolume(environmentID: String = "0", spec: Data) async throws -> Data {
        var req = Mobile_V1_CreateVolumeRequest()
        req.environmentID = environmentID
        req.specJson = spec
        let request = req
        let md = authMetadata()
        let response = try await unaryAuthenticated { service in
            try await service.createVolume(request, metadata: md)
        }
        return response.volumeJson
    }

    public func deleteVolume(environmentID: String = "0", name: String, force: Bool = false) async throws {
        var req = Mobile_V1_DeleteVolumeRequest()
        req.environmentID = environmentID
        req.name = name
        req.force = force
        let request = req
        let md = authMetadata()
        _ = try await unaryAuthenticated { service in
            try await service.deleteVolume(request, metadata: md)
        }
    }

    public func pruneVolumes(environmentID: String = "0") async throws -> Data {
        var req = Mobile_V1_PruneVolumesRequest()
        req.environmentID = environmentID
        let request = req
        let md = authMetadata()
        let response = try await unaryAuthenticated { service in
            try await service.pruneVolumes(request, metadata: md)
        }
        return response.reportJson
    }

    // MARK: - Networks

    public func listNetworks(environmentID: String = "0") async throws -> Data {
        var req = Mobile_V1_ListNetworksRequest()
        req.environmentID = environmentID
        let request = req
        let md = authMetadata()
        let response = try await unaryAuthenticated { service in
            try await service.listNetworks(request, metadata: md)
        }
        return response.networksJson
    }

    public func createNetwork(environmentID: String = "0", spec: Data) async throws -> Data {
        var req = Mobile_V1_CreateNetworkRequest()
        req.environmentID = environmentID
        req.specJson = spec
        let request = req
        let md = authMetadata()
        let response = try await unaryAuthenticated { service in
            try await service.createNetwork(request, metadata: md)
        }
        return response.networkJson
    }

    public func deleteNetwork(environmentID: String = "0", id: String) async throws {
        var req = Mobile_V1_DeleteNetworkRequest()
        req.environmentID = environmentID
        req.id = id
        let request = req
        let md = authMetadata()
        _ = try await unaryAuthenticated { service in
            try await service.deleteNetwork(request, metadata: md)
        }
    }

    public func pruneNetworks(environmentID: String = "0") async throws -> Data {
        var req = Mobile_V1_PruneNetworksRequest()
        req.environmentID = environmentID
        let request = req
        let md = authMetadata()
        let response = try await unaryAuthenticated { service in
            try await service.pruneNetworks(request, metadata: md)
        }
        return response.reportJson
    }

    // MARK: - Projects (read)

    public func listProjects(environmentID: String = "0") async throws -> Data {
        var req = Mobile_V1_ListProjectsRequest()
        req.environmentID = environmentID
        let request = req
        let md = authMetadata()
        let response = try await unaryAuthenticated { service in
            try await service.listProjects(request, metadata: md)
        }
        return response.projectsJson
    }

    public func getProject(environmentID: String = "0", id: String) async throws -> Data {
        var req = Mobile_V1_GetProjectRequest()
        req.environmentID = environmentID
        req.id = id
        let request = req
        let md = authMetadata()
        let response = try await unaryAuthenticated { service in
            try await service.getProject(request, metadata: md)
        }
        return response.projectJson
    }

    // MARK: - Helpers

    private enum ContainerAction { case start, stop, restart, redeploy }

    private func runContainerAction(environmentID: String, id: String, kind: ContainerAction) async throws {
        var req = Mobile_V1_ContainerActionRequest()
        req.environmentID = environmentID
        req.id = id
        let request = req
        let md = authMetadata()
        _ = try await unaryAuthenticated { service in
            switch kind {
            case .start:    return try await service.startContainer(request, metadata: md)
            case .stop:     return try await service.stopContainer(request, metadata: md)
            case .restart:  return try await service.restartContainer(request, metadata: md)
            case .redeploy: return try await service.redeployContainer(request, metadata: md)
            }
        }
    }

    internal func unaryAuthenticated<Result: Sendable>(
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

/// Formats a swift gRPC client error into a human-readable string. Falls back
/// to `localizedDescription` for non-gRPC errors. Useful for surfacing
/// `RPCError`s in UI layers that don't import `GRPCCore` directly.
public func describeGRPCError(_ error: any Error) -> String {
    if let rpc = error as? RPCError {
        let codeName = "\(rpc.code)"
        if rpc.message.isEmpty {
            return "gRPC \(codeName)"
        }
        return "gRPC \(codeName): \(rpc.message)"
    }
    if let arcane = error as? ArcaneGRPCError {
        switch arcane {
        case .missingDeviceToken: return "Device not paired"
        case .invalidServerURL: return "Invalid server URL"
        case .transportFailed(let message): return "Transport error: \(message)"
        }
    }
    return error.localizedDescription
}
