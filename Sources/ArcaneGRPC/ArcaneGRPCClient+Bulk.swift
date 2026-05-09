import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2
import SwiftProtobuf

// Tier 2 / 3 method wrappers on ArcaneGRPCClient. These mirror the JSON-
// passthrough RPCs and return raw `Data` for callers to decode using the
// existing libarcane-swift Codable types.
extension ArcaneGRPCClient {

    // MARK: - Container extras

    public func pauseContainer(environmentID: String = "0", id: String) async throws {
        _ = try await callContainerAction(environmentID: environmentID, id: id) { service, req, md in
            try await service.pauseContainer(req, metadata: md)
        }
    }
    public func unpauseContainer(environmentID: String = "0", id: String) async throws {
        _ = try await callContainerAction(environmentID: environmentID, id: id) { service, req, md in
            try await service.unpauseContainer(req, metadata: md)
        }
    }
    public func killContainer(environmentID: String = "0", id: String) async throws {
        _ = try await callContainerAction(environmentID: environmentID, id: id) { service, req, md in
            try await service.killContainer(req, metadata: md)
        }
    }
    public func renameContainer(environmentID: String = "0", id: String, newName: String) async throws {
        var req = Mobile_V1_RenameContainerRequest()
        req.environmentID = environmentID
        req.id = id
        req.newName = newName
        let request = req
        let md = authMetadata()
        _ = try await unaryAuthenticated { service in
            try await service.renameContainer(request, metadata: md)
        }
    }

    // MARK: - Images

    public func listImages(environmentID: String = "0") async throws -> Data {
        try await callEnvIDJSON(environmentID: environmentID) { svc, req, md in
            try await svc.listImages(req, metadata: md)
        }
    }
    public func inspectImage(environmentID: String = "0", id: String) async throws -> Data {
        try await callEnvIDIDJSON(environmentID: environmentID, id: id) { svc, req, md in
            try await svc.inspectImage(req, metadata: md)
        }
    }
    public func deleteImage(environmentID: String = "0", id: String) async throws {
        try await callEnvIDIDAction(environmentID: environmentID, id: id) { svc, req, md in
            try await svc.deleteImage(req, metadata: md)
        }
    }
    public func pruneImages(environmentID: String = "0") async throws -> Data {
        var req = Mobile_V1_EnvIDOnlyRequest()
        req.environmentID = environmentID
        let request = req
        let md = authMetadata()
        let resp = try await unaryAuthenticated { svc in
            try await svc.pruneImages(request, metadata: md)
        }
        return resp.reportJson
    }

    // MARK: - Image updates

    public func getImageUpdateSummary(environmentID: String = "0") async throws -> Data {
        try await callEnvIDJSON(environmentID: environmentID) { svc, req, md in
            try await svc.getImageUpdateSummary(req, metadata: md)
        }
    }
    public func getImageUpdatesByRefs(environmentID: String = "0", refs: [String]) async throws -> Data {
        var req = Mobile_V1_GetImageUpdatesByRefsRequest()
        req.environmentID = environmentID
        req.refs = refs
        let request = req
        let md = authMetadata()
        let resp = try await unaryAuthenticated { svc in
            try await svc.getImageUpdatesByRefs(request, metadata: md)
        }
        return resp.payload
    }
    public func checkImageUpdates(environmentID: String = "0", query: String = "") async throws -> Data {
        try await callEnvIDQueryJSON(environmentID: environmentID, query: query) { svc, req, md in
            try await svc.checkImageUpdates(req, metadata: md)
        }
    }
    public func checkAllImageUpdates(environmentID: String = "0") async throws {
        var req = Mobile_V1_EnvIDOnlyRequest()
        req.environmentID = environmentID
        let request = req
        let md = authMetadata()
        _ = try await unaryAuthenticated { svc in
            try await svc.checkAllImageUpdates(request, metadata: md)
        }
    }
    public func checkImageUpdate(environmentID: String = "0", id: String) async throws -> Data {
        try await callEnvIDIDJSON(environmentID: environmentID, id: id) { svc, req, md in
            try await svc.checkImageUpdate(req, metadata: md)
        }
    }

    // MARK: - Vulnerabilities

    public func getVulnerabilityScannerStatus(environmentID: String = "0") async throws -> Data {
        try await callEnvIDJSON(environmentID: environmentID) { svc, req, md in
            try await svc.getVulnerabilityScannerStatus(req, metadata: md)
        }
    }
    public func getImageVulnerabilitySummary(environmentID: String = "0", id: String) async throws -> Data {
        try await callEnvIDIDJSON(environmentID: environmentID, id: id) { svc, req, md in
            try await svc.getImageVulnerabilitySummary(req, metadata: md)
        }
    }
    public func listImageVulnerabilities(environmentID: String = "0", id: String, query: String = "") async throws -> Data {
        var req = Mobile_V1_EnvIDAndIDAndQueryRequest()
        req.environmentID = environmentID
        req.id = id
        req.query = query
        let request = req
        let md = authMetadata()
        let resp = try await unaryAuthenticated { svc in
            try await svc.listImageVulnerabilities(request, metadata: md)
        }
        return resp.payload
    }
    public func scanImageVulnerabilities(environmentID: String = "0", id: String) async throws -> Data {
        try await callEnvIDIDJSON(environmentID: environmentID, id: id) { svc, req, md in
            try await svc.scanImageVulnerabilities(req, metadata: md)
        }
    }
    public func getAllVulnerabilitiesSummary(environmentID: String = "0") async throws -> Data {
        try await callEnvIDJSON(environmentID: environmentID) { svc, req, md in
            try await svc.getAllVulnerabilitiesSummary(req, metadata: md)
        }
    }
    public func getVulnerabilityImageOptions(environmentID: String = "0", query: String = "") async throws -> Data {
        try await callEnvIDQueryJSON(environmentID: environmentID, query: query) { svc, req, md in
            try await svc.getVulnerabilityImageOptions(req, metadata: md)
        }
    }
    public func listAllVulnerabilities(environmentID: String = "0", query: String = "") async throws -> Data {
        try await callEnvIDQueryJSON(environmentID: environmentID, query: query) { svc, req, md in
            try await svc.listAllVulnerabilities(req, metadata: md)
        }
    }
    public func ignoreVulnerability(environmentID: String = "0", body: Data) async throws -> Data {
        try await callEnvIDBodyJSON(environmentID: environmentID, body: body) { svc, req, md in
            try await svc.ignoreVulnerability(req, metadata: md)
        }
    }
    public func deleteVulnerabilityIgnore(environmentID: String = "0", id: String) async throws {
        try await callEnvIDIDAction(environmentID: environmentID, id: id) { svc, req, md in
            try await svc.deleteVulnerabilityIgnore(req, metadata: md)
        }
    }

    // MARK: - Projects (mutations)

    public func createProject(environmentID: String = "0", body: Data) async throws -> Data {
        try await callEnvIDBodyJSON(environmentID: environmentID, body: body) { svc, req, md in
            try await svc.createProject(req, metadata: md)
        }
    }
    public func updateProject(environmentID: String = "0", id: String, body: Data) async throws -> Data {
        var req = Mobile_V1_EnvIDAndIDAndJSONBodyRequest()
        req.environmentID = environmentID
        req.id = id
        req.body = body
        let request = req
        let md = authMetadata()
        let resp = try await unaryAuthenticated { svc in
            try await svc.updateProject(request, metadata: md)
        }
        return resp.payload
    }
    public func deleteProject(environmentID: String = "0", id: String) async throws {
        try await callEnvIDIDAction(environmentID: environmentID, id: id) { svc, req, md in
            try await svc.deleteProject(req, metadata: md)
        }
    }
    public func startProject(environmentID: String = "0", id: String) async throws {
        try await callEnvIDIDAction(environmentID: environmentID, id: id) { svc, req, md in
            try await svc.startProject(req, metadata: md)
        }
    }
    public func stopProject(environmentID: String = "0", id: String) async throws {
        try await callEnvIDIDAction(environmentID: environmentID, id: id) { svc, req, md in
            try await svc.stopProject(req, metadata: md)
        }
    }
    public func destroyProject(environmentID: String = "0", id: String) async throws {
        try await callEnvIDIDAction(environmentID: environmentID, id: id) { svc, req, md in
            try await svc.destroyProject(req, metadata: md)
        }
    }

    // MARK: - Environments

    public func listEnvironments() async throws -> Data {
        try await callEmptyJSON { svc, req, md in
            try await svc.listEnvironments(req, metadata: md)
        }
    }
    public func createEnvironment(body: Data) async throws -> Data {
        try await callBodyJSON(body: body) { svc, req, md in
            try await svc.createEnvironment(req, metadata: md)
        }
    }
    public func testEnvironment(environmentID: String) async throws -> Data {
        try await callEnvIDJSON(environmentID: environmentID) { svc, req, md in
            try await svc.testEnvironment(req, metadata: md)
        }
    }

    // MARK: - Settings

    public func getSettings(environmentID: String = "0") async throws -> Data {
        try await callEnvIDJSON(environmentID: environmentID) { svc, req, md in
            try await svc.getSettings(req, metadata: md)
        }
    }
    public func updateSettings(environmentID: String = "0", body: Data) async throws -> Data {
        try await callEnvIDBodyJSON(environmentID: environmentID, body: body) { svc, req, md in
            try await svc.updateSettings(req, metadata: md)
        }
    }
    public func getOidcStatus() async throws -> Data {
        try await callEmptyJSON { svc, req, md in
            try await svc.getOidcStatus(req, metadata: md)
        }
    }

    // MARK: - Notifications

    public func getNotificationSettings(environmentID: String = "0") async throws -> Data {
        try await callEnvIDJSON(environmentID: environmentID) { svc, req, md in
            try await svc.getNotificationSettings(req, metadata: md)
        }
    }
    public func saveNotificationProvider(environmentID: String = "0", body: Data) async throws -> Data {
        try await callEnvIDBodyJSON(environmentID: environmentID, body: body) { svc, req, md in
            try await svc.saveNotificationProvider(req, metadata: md)
        }
    }
    public func deleteNotificationProvider(environmentID: String = "0", id: String) async throws {
        try await callEnvIDIDAction(environmentID: environmentID, id: id) { svc, req, md in
            try await svc.deleteNotificationProvider(req, metadata: md)
        }
    }
    public func testNotificationProvider(environmentID: String = "0", id: String, body: Data) async throws {
        var req = Mobile_V1_EnvIDAndIDAndJSONBodyRequest()
        req.environmentID = environmentID
        req.id = id
        req.body = body
        let request = req
        let md = authMetadata()
        _ = try await unaryAuthenticated { svc in
            try await svc.testNotificationProvider(request, metadata: md)
        }
    }
    public func getApprise(environmentID: String = "0") async throws -> Data {
        try await callEnvIDJSON(environmentID: environmentID) { svc, req, md in
            try await svc.getApprise(req, metadata: md)
        }
    }
    public func updateApprise(environmentID: String = "0", body: Data) async throws -> Data {
        try await callEnvIDBodyJSON(environmentID: environmentID, body: body) { svc, req, md in
            try await svc.updateApprise(req, metadata: md)
        }
    }
    public func testApprise(environmentID: String = "0", body: Data) async throws {
        var req = Mobile_V1_EnvIDAndJSONBodyRequest()
        req.environmentID = environmentID
        req.body = body
        let request = req
        let md = authMetadata()
        _ = try await unaryAuthenticated { svc in
            try await svc.testApprise(request, metadata: md)
        }
    }

    // MARK: - Webhooks

    public func listWebhooks(environmentID: String = "0") async throws -> Data {
        try await callEnvIDJSON(environmentID: environmentID) { svc, req, md in
            try await svc.listWebhooks(req, metadata: md)
        }
    }
    public func createWebhook(environmentID: String = "0", body: Data) async throws -> Data {
        try await callEnvIDBodyJSON(environmentID: environmentID, body: body) { svc, req, md in
            try await svc.createWebhook(req, metadata: md)
        }
    }
    public func updateWebhook(environmentID: String = "0", id: String, body: Data) async throws -> Data {
        var req = Mobile_V1_EnvIDAndIDAndJSONBodyRequest()
        req.environmentID = environmentID
        req.id = id
        req.body = body
        let request = req
        let md = authMetadata()
        let resp = try await unaryAuthenticated { svc in
            try await svc.updateWebhook(request, metadata: md)
        }
        return resp.payload
    }
    public func deleteWebhook(environmentID: String = "0", id: String) async throws {
        try await callEnvIDIDAction(environmentID: environmentID, id: id) { svc, req, md in
            try await svc.deleteWebhook(req, metadata: md)
        }
    }

    // MARK: - Users

    public func listUsers() async throws -> Data {
        try await callEmptyJSON { svc, req, md in
            try await svc.listUsers(req, metadata: md)
        }
    }
    public func createUser(body: Data) async throws -> Data {
        try await callBodyJSON(body: body) { svc, req, md in
            try await svc.createUser(req, metadata: md)
        }
    }
    public func updateUser(id: String, body: Data) async throws -> Data {
        try await callIDBodyJSON(id: id, body: body) { svc, req, md in
            try await svc.updateUser(req, metadata: md)
        }
    }
    public func deleteUser(id: String) async throws {
        try await callIDAction(id: id) { svc, req, md in
            try await svc.deleteUser(req, metadata: md)
        }
    }

    // MARK: - API keys

    public func listApiKeys() async throws -> Data {
        try await callEmptyJSON { svc, req, md in
            try await svc.listApiKeys(req, metadata: md)
        }
    }
    public func createApiKey(body: Data) async throws -> Data {
        try await callBodyJSON(body: body) { svc, req, md in
            try await svc.createApiKey(req, metadata: md)
        }
    }
    public func deleteApiKey(id: String) async throws {
        try await callIDAction(id: id) { svc, req, md in
            try await svc.deleteApiKey(req, metadata: md)
        }
    }

    // MARK: - Container registries

    public func listContainerRegistries() async throws -> Data {
        try await callEmptyJSON { svc, req, md in
            try await svc.listContainerRegistries(req, metadata: md)
        }
    }
    public func createContainerRegistry(body: Data) async throws -> Data {
        try await callBodyJSON(body: body) { svc, req, md in
            try await svc.createContainerRegistry(req, metadata: md)
        }
    }
    public func updateContainerRegistry(id: String, body: Data) async throws -> Data {
        try await callIDBodyJSON(id: id, body: body) { svc, req, md in
            try await svc.updateContainerRegistry(req, metadata: md)
        }
    }
    public func deleteContainerRegistry(id: String) async throws {
        try await callIDAction(id: id) { svc, req, md in
            try await svc.deleteContainerRegistry(req, metadata: md)
        }
    }

    // MARK: - Templates

    public func listTemplates() async throws -> Data {
        try await callEmptyJSON { svc, req, md in
            try await svc.listTemplates(req, metadata: md)
        }
    }
    public func getTemplateContent(id: String) async throws -> Data {
        try await callIDJSON(id: id) { svc, req, md in
            try await svc.getTemplateContent(req, metadata: md)
        }
    }
    public func listTemplateRegistries() async throws -> Data {
        try await callEmptyJSON { svc, req, md in
            try await svc.listTemplateRegistries(req, metadata: md)
        }
    }
    public func createTemplateRegistry(body: Data) async throws -> Data {
        try await callBodyJSON(body: body) { svc, req, md in
            try await svc.createTemplateRegistry(req, metadata: md)
        }
    }
    public func updateTemplateRegistry(id: String, body: Data) async throws -> Data {
        try await callIDBodyJSON(id: id, body: body) { svc, req, md in
            try await svc.updateTemplateRegistry(req, metadata: md)
        }
    }
    public func deleteTemplateRegistry(id: String) async throws {
        try await callIDAction(id: id) { svc, req, md in
            try await svc.deleteTemplateRegistry(req, metadata: md)
        }
    }

    // MARK: - System

    public func pruneSystem(environmentID: String = "0", body: Data) async throws -> Data {
        try await callEnvIDBodyJSON(environmentID: environmentID, body: body) { svc, req, md in
            try await svc.pruneSystem(req, metadata: md)
        }
    }

    // MARK: - Streaming (server-streaming RPCs)

    /// Server-streams container log chunks. The closure is invoked for each
    /// data chunk; throws once the stream ends (or with the underlying error).
    public func streamContainerLogs(
        environmentID: String = "0",
        id: String,
        follow: Bool = true,
        tail: String = "100",
        timestamps: Bool = false,
        stdout: Bool = true,
        stderr: Bool = true,
        since: String = "",
        until: String = "",
        onChunk: @Sendable @escaping (Data) -> Void
    ) async throws {
        var req = Mobile_V1_StreamContainerLogsRequest()
        req.environmentID = environmentID
        req.id = id
        req.follow = follow
        req.tail = tail
        req.timestamps = timestamps
        req.stdout = stdout
        req.stderr = stderr
        req.since = since
        req.until = until
        let request = req
        try await consumeStream { client, md in
            try await Mobile_V1_MobileService.Client(wrapping: client)
                .streamContainerLogs(request, metadata: md) { stream in
                    for try await frame in stream.messages {
                        if case .data(let chunk) = frame.payload {
                            onChunk(chunk)
                        }
                    }
                }
        }
    }

    public func streamContainerStats(environmentID: String = "0", id: String, onChunk: @Sendable @escaping (Data) -> Void) async throws {
        var req = Mobile_V1_EnvIDAndIDRequest()
        req.environmentID = environmentID
        req.id = id
        let request = req
        try await consumeStream { client, md in
            try await Mobile_V1_MobileService.Client(wrapping: client)
                .streamContainerStats(request, metadata: md) { stream in
                    for try await frame in stream.messages {
                        if case .data(let chunk) = frame.payload {
                            onChunk(chunk)
                        }
                    }
                }
        }
    }

    public func streamProjectLogs(
        environmentID: String = "0",
        id: String,
        follow: Bool = true,
        tail: String = "100",
        timestamps: Bool = false,
        onChunk: @Sendable @escaping (Data) -> Void
    ) async throws {
        var req = Mobile_V1_StreamProjectLogsRequest()
        req.environmentID = environmentID
        req.id = id
        req.follow = follow
        req.tail = tail
        req.timestamps = timestamps
        let request = req
        try await consumeStream { client, md in
            try await Mobile_V1_MobileService.Client(wrapping: client)
                .streamProjectLogs(request, metadata: md) { stream in
                    for try await frame in stream.messages {
                        if case .data(let chunk) = frame.payload {
                            onChunk(chunk)
                        }
                    }
                }
        }
    }

    public func streamSystemStats(environmentID: String = "0", intervalMs: Int32 = 0, onChunk: @Sendable @escaping (Data) -> Void) async throws {
        var req = Mobile_V1_StreamSystemStatsRequest()
        req.environmentID = environmentID
        req.intervalMs = intervalMs
        let request = req
        try await consumeStream { client, md in
            try await Mobile_V1_MobileService.Client(wrapping: client)
                .streamSystemStats(request, metadata: md) { stream in
                    for try await frame in stream.messages {
                        if case .data(let chunk) = frame.payload {
                            onChunk(chunk)
                        }
                    }
                }
        }
    }

    public func streamPullImage(environmentID: String = "0", ref: String, authCredentialsJson: Data = Data(), onChunk: @Sendable @escaping (Data) -> Void) async throws {
        var req = Mobile_V1_PullImageRequest()
        req.environmentID = environmentID
        req.ref = ref
        req.authCredentialsJson = authCredentialsJson
        let request = req
        try await consumeStream { client, md in
            try await Mobile_V1_MobileService.Client(wrapping: client)
                .streamPullImage(request, metadata: md) { stream in
                    for try await frame in stream.messages {
                        if case .data(let chunk) = frame.payload {
                            onChunk(chunk)
                        }
                    }
                }
        }
    }

    // MARK: - Helpers (typed wrappers to keep the public methods one-liners)

    private func callContainerAction(
        environmentID: String,
        id: String,
        block: @Sendable @escaping (Mobile_V1_MobileService.Client<HTTP2ClientTransport.Posix>, Mobile_V1_ContainerActionRequest, Metadata) async throws -> Mobile_V1_ActionResult
    ) async throws -> Mobile_V1_ActionResult {
        var req = Mobile_V1_ContainerActionRequest()
        req.environmentID = environmentID
        req.id = id
        let request = req
        let md = authMetadata()
        return try await unaryAuthenticated { svc in
            try await block(svc, request, md)
        }
    }

    private func callEnvIDJSON(
        environmentID: String,
        block: @Sendable @escaping (Mobile_V1_MobileService.Client<HTTP2ClientTransport.Posix>, Mobile_V1_EnvIDOnlyRequest, Metadata) async throws -> Mobile_V1_JSONResponse
    ) async throws -> Data {
        var req = Mobile_V1_EnvIDOnlyRequest()
        req.environmentID = environmentID
        let request = req
        let md = authMetadata()
        let resp = try await unaryAuthenticated { svc in
            try await block(svc, request, md)
        }
        return resp.payload
    }

    private func callEnvIDIDJSON(
        environmentID: String,
        id: String,
        block: @Sendable @escaping (Mobile_V1_MobileService.Client<HTTP2ClientTransport.Posix>, Mobile_V1_EnvIDAndIDRequest, Metadata) async throws -> Mobile_V1_JSONResponse
    ) async throws -> Data {
        var req = Mobile_V1_EnvIDAndIDRequest()
        req.environmentID = environmentID
        req.id = id
        let request = req
        let md = authMetadata()
        let resp = try await unaryAuthenticated { svc in
            try await block(svc, request, md)
        }
        return resp.payload
    }

    private func callEnvIDQueryJSON(
        environmentID: String,
        query: String,
        block: @Sendable @escaping (Mobile_V1_MobileService.Client<HTTP2ClientTransport.Posix>, Mobile_V1_EnvIDAndQueryRequest, Metadata) async throws -> Mobile_V1_JSONResponse
    ) async throws -> Data {
        var req = Mobile_V1_EnvIDAndQueryRequest()
        req.environmentID = environmentID
        req.query = query
        let request = req
        let md = authMetadata()
        let resp = try await unaryAuthenticated { svc in
            try await block(svc, request, md)
        }
        return resp.payload
    }

    private func callEnvIDBodyJSON(
        environmentID: String,
        body: Data,
        block: @Sendable @escaping (Mobile_V1_MobileService.Client<HTTP2ClientTransport.Posix>, Mobile_V1_EnvIDAndJSONBodyRequest, Metadata) async throws -> Mobile_V1_JSONResponse
    ) async throws -> Data {
        var req = Mobile_V1_EnvIDAndJSONBodyRequest()
        req.environmentID = environmentID
        req.body = body
        let request = req
        let md = authMetadata()
        let resp = try await unaryAuthenticated { svc in
            try await block(svc, request, md)
        }
        return resp.payload
    }

    private func callEnvIDIDAction(
        environmentID: String,
        id: String,
        block: @Sendable @escaping (Mobile_V1_MobileService.Client<HTTP2ClientTransport.Posix>, Mobile_V1_EnvIDAndIDRequest, Metadata) async throws -> Mobile_V1_ActionResult
    ) async throws {
        var req = Mobile_V1_EnvIDAndIDRequest()
        req.environmentID = environmentID
        req.id = id
        let request = req
        let md = authMetadata()
        _ = try await unaryAuthenticated { svc in
            try await block(svc, request, md)
        }
    }

    private func callEmptyJSON(
        block: @Sendable @escaping (Mobile_V1_MobileService.Client<HTTP2ClientTransport.Posix>, Mobile_V1_EmptyRequest, Metadata) async throws -> Mobile_V1_JSONResponse
    ) async throws -> Data {
        let request = Mobile_V1_EmptyRequest()
        let md = authMetadata()
        let resp = try await unaryAuthenticated { svc in
            try await block(svc, request, md)
        }
        return resp.payload
    }

    private func callBodyJSON(
        body: Data,
        block: @Sendable @escaping (Mobile_V1_MobileService.Client<HTTP2ClientTransport.Posix>, Mobile_V1_JSONBodyRequest, Metadata) async throws -> Mobile_V1_JSONResponse
    ) async throws -> Data {
        var req = Mobile_V1_JSONBodyRequest()
        req.body = body
        let request = req
        let md = authMetadata()
        let resp = try await unaryAuthenticated { svc in
            try await block(svc, request, md)
        }
        return resp.payload
    }

    private func callIDJSON(
        id: String,
        block: @Sendable @escaping (Mobile_V1_MobileService.Client<HTTP2ClientTransport.Posix>, Mobile_V1_IDOnlyRequest, Metadata) async throws -> Mobile_V1_JSONResponse
    ) async throws -> Data {
        var req = Mobile_V1_IDOnlyRequest()
        req.id = id
        let request = req
        let md = authMetadata()
        let resp = try await unaryAuthenticated { svc in
            try await block(svc, request, md)
        }
        return resp.payload
    }

    private func callIDBodyJSON(
        id: String,
        body: Data,
        block: @Sendable @escaping (Mobile_V1_MobileService.Client<HTTP2ClientTransport.Posix>, Mobile_V1_IDAndJSONBodyRequest, Metadata) async throws -> Mobile_V1_JSONResponse
    ) async throws -> Data {
        var req = Mobile_V1_IDAndJSONBodyRequest()
        req.id = id
        req.body = body
        let request = req
        let md = authMetadata()
        let resp = try await unaryAuthenticated { svc in
            try await block(svc, request, md)
        }
        return resp.payload
    }

    private func callIDAction(
        id: String,
        block: @Sendable @escaping (Mobile_V1_MobileService.Client<HTTP2ClientTransport.Posix>, Mobile_V1_IDOnlyRequest, Metadata) async throws -> Mobile_V1_ActionResult
    ) async throws {
        var req = Mobile_V1_IDOnlyRequest()
        req.id = id
        let request = req
        let md = authMetadata()
        _ = try await unaryAuthenticated { svc in
            try await block(svc, request, md)
        }
    }

    private func consumeStream(
        block: @Sendable @escaping (GRPCClient<HTTP2ClientTransport.Posix>, Metadata) async throws -> Void
    ) async throws {
        guard configuration.deviceToken != nil else {
            throw ArcaneGRPCError.missingDeviceToken
        }
        let client = try await ensureClient()
        let md = authMetadata()
        try await block(client, md)
    }

    // Re-expose the unaryAuthenticated helper to extension methods.
    fileprivate func unaryAuthenticatedExt<Result: Sendable>(
        _ perform: @Sendable (Mobile_V1_MobileService.Client<HTTP2ClientTransport.Posix>) async throws -> Result
    ) async throws -> Result {
        try await unaryAuthenticated(perform)
    }
}
