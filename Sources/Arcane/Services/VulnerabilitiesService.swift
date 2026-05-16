import Foundation

public struct VulnerabilitiesService: Sendable {
    private let rest: RESTService

    init(rest: RESTService) {
        self.rest = rest
    }

    // MARK: - Scans (per-image)

    /// Initiate a new Trivy scan for an image. Returns the resulting scan record
    /// once the scan completes.
    public func scanImage(envID: EnvironmentID? = nil, imageId: String) async throws -> VulnerabilityScanResult {
        try await rest.post(
            rest.environmentPath(envID, "images/\(imageId)/vulnerabilities/scan"),
            body: Optional<EmptyBody>.none
        )
    }

    /// Most recent full scan result for an image.
    public func scanResult(envID: EnvironmentID? = nil, imageId: String) async throws -> VulnerabilityScanResult {
        try await rest.get(rest.environmentPath(envID, "images/\(imageId)/vulnerabilities"))
    }

    /// Compact severity summary for an image. Suitable for list views.
    public func scanSummary(envID: EnvironmentID? = nil, imageId: String) async throws -> VulnerabilityScanSummary {
        try await rest.get(rest.environmentPath(envID, "images/\(imageId)/vulnerabilities/summary"))
    }

    /// Batch lookup of scan summaries keyed by image ID.
    public func scanSummaries(
        envID: EnvironmentID? = nil,
        imageIds: [String]
    ) async throws -> VulnerabilityScanSummariesResponse {
        let body = VulnerabilityScanSummariesRequest(imageIds: imageIds)
        return try await rest.post(rest.environmentPath(envID, "images/vulnerabilities/summaries"), body: body)
    }

    /// Paginated list of vulnerabilities for a specific image.
    public func listForImage(
        envID: EnvironmentID? = nil,
        imageId: String,
        query: SearchPaginationSort = .init(),
        severity: String? = nil
    ) async throws -> PaginatedResponse<Vulnerability> {
        var items = query.nonPaginationQueryItems
        if let severity { items.append(URLQueryItem(name: "severity", value: severity)) }
        return try await rest.paginated(
            rest.environmentPath(envID, "images/\(imageId)/vulnerabilities/list"),
            start: query.start ?? 0,
            limit: query.limit ?? 20,
            query: items
        )
    }

    // MARK: - Environment-wide

    /// Status of the bundled Trivy scanner.
    public func scannerStatus(envID: EnvironmentID? = nil) async throws -> VulnerabilityScannerStatus {
        try await rest.get(rest.environmentPath(envID, "vulnerabilities/scanner-status"))
    }

    /// Aggregated vulnerability counts across all images in the environment.
    public func environmentSummary(envID: EnvironmentID? = nil) async throws -> EnvironmentVulnerabilitySummary {
        try await rest.get(rest.environmentPath(envID, "vulnerabilities/summary"))
    }

    /// Paginated list of vulnerabilities across all scanned images in the environment.
    public func listAll(
        envID: EnvironmentID? = nil,
        query: SearchPaginationSort = .init(),
        severity: String? = nil,
        imageName: String? = nil
    ) async throws -> PaginatedResponse<VulnerabilityWithImage> {
        var items = query.nonPaginationQueryItems
        if let severity { items.append(URLQueryItem(name: "severity", value: severity)) }
        if let imageName { items.append(URLQueryItem(name: "imageName", value: imageName)) }
        return try await rest.paginated(
            rest.environmentPath(envID, "vulnerabilities/all"),
            start: query.start ?? 0,
            limit: query.limit ?? 20,
            query: items
        )
    }

    /// Distinct image names available for vulnerability filtering.
    public func imageOptions(
        envID: EnvironmentID? = nil,
        severity: String? = nil
    ) async throws -> [String] {
        var items: [URLQueryItem] = []
        if let severity { items.append(URLQueryItem(name: "severity", value: severity)) }
        return try await rest.get(rest.environmentPath(envID, "vulnerabilities/image-options"), query: items)
    }

    // MARK: - Ignore records

    /// Create an ignore record for a specific vulnerability finding.
    public func ignore(
        envID: EnvironmentID? = nil,
        payload: VulnerabilityIgnorePayload
    ) async throws -> IgnoredVulnerability {
        try await rest.post(rest.environmentPath(envID, "vulnerabilities/ignore"), body: payload)
    }

    /// Remove an existing ignore record.
    public func unignore(envID: EnvironmentID? = nil, ignoreId: String) async throws {
        try await rest.deleteVoid(rest.environmentPath(envID, "vulnerabilities/ignore/\(ignoreId)"))
    }

    /// Paginated list of currently ignored vulnerabilities.
    public func listIgnored(
        envID: EnvironmentID? = nil,
        query: SearchPaginationSort = .init()
    ) async throws -> PaginatedResponse<IgnoredVulnerability> {
        try await rest.paginated(
            rest.environmentPath(envID, "vulnerabilities/ignored"),
            start: query.start ?? 0,
            limit: query.limit ?? 20,
            query: query.nonPaginationQueryItems
        )
    }
}
