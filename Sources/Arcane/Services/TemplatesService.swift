import Foundation

/// TemplatesService manages compose templates, registries, default templates, and per-environment template variables.
public struct TemplatesService: Sendable {
  private let rest: RESTService

  init(rest: RESTService) {
    self.rest = rest
  }

  // MARK: - Templates

  /// List templates with pagination. Server-side filters: `type` (comma-separated, e.g. `"true,false"`).
  public func listPaginated(
    search: String? = nil,
    sort: String? = nil,
    order: SortOrder? = nil,
    start: Int = 0,
    limit: Int = 20,
    type: String? = nil
  ) async throws -> PaginatedResponse<Template> {
    var query: [URLQueryItem] = []
    if let search { query.append(URLQueryItem(name: "search", value: search)) }
    if let sort { query.append(URLQueryItem(name: "sort", value: sort)) }
    if let order { query.append(URLQueryItem(name: "order", value: order.rawValue)) }
    if let type { query.append(URLQueryItem(name: "type", value: type)) }
    return try await rest.transport.paginated("templates", start: start, limit: limit, query: query)
  }

  /// List all templates without pagination.
  public func listAll() async throws -> [Template] {
    try await rest.get("templates/all")
  }

  /// Get a template by ID.
  public func get(id: String) async throws -> Template {
    try await rest.get("templates/\(id)")
  }

  /// Get a template's content with parsed services and env variables.
  public func getContent(id: String) async throws -> TemplateContent {
    try await rest.get("templates/\(id)/content")
  }

  /// Create a new local template.
  public func create(_ body: CreateTemplate) async throws -> Template {
    try await rest.post("templates", body: body)
  }

  /// Update a local template.
  public func update(id: String, body: UpdateTemplate) async throws -> Template {
    try await rest.put("templates/\(id)", body: body)
  }

  /// Delete a template.
  public func delete(id: String) async throws {
    try await rest.deleteVoid("templates/\(id)")
  }

  /// Download a remote template into local storage.
  public func download(id: String) async throws -> Template {
    try await rest.post("templates/\(id)/download", body: EmptyBody?.none)
  }

  // MARK: - Default templates

  /// Get the default compose and env templates.
  public func getDefaults() async throws -> DefaultTemplates {
    try await rest.get("templates/default")
  }

  /// Save the default compose and env templates.
  public func saveDefaults(_ body: SaveDefaultTemplates) async throws {
    try await rest.postVoid("templates/default", body: body)
  }

  // MARK: - Registries

  /// Get all configured template registries.
  public func listRegistries() async throws -> [TemplateRegistry] {
    try await rest.get("templates/registries")
  }

  /// Create a new template registry.
  public func createRegistry(_ body: CreateTemplateRegistry) async throws -> TemplateRegistry {
    try await rest.post("templates/registries", body: body)
  }

  /// Update an existing template registry.
  public func updateRegistry(id: String, body: UpdateTemplateRegistry) async throws {
    try await rest.putVoid("templates/registries/\(id)", body: body)
  }

  /// Delete a template registry.
  public func deleteRegistry(id: String) async throws {
    try await rest.deleteVoid("templates/registries/\(id)")
  }

  /// Fetch the contents of a remote registry by URL.
  public func fetchRegistry(url: String) async throws -> RemoteTemplateRegistry {
    let query = [URLQueryItem(name: "url", value: url)]
    return try await rest.get("templates/fetch", query: query)
  }

  // MARK: - Per-environment global variables

  /// Get the global template variables for an environment.
  public func getGlobalVariables(envID: EnvironmentID? = nil) async throws -> [EnvVariable] {
    try await rest.get(rest.environmentPath(envID, "templates/variables"))
  }

  /// Update the global template variables for an environment.
  public func updateGlobalVariables(_ variables: [EnvVariable], envID: EnvironmentID? = nil)
    async throws
  {
    try await rest.putVoid(
      rest.environmentPath(envID, "templates/variables"), body: EnvVariables(variables: variables))
  }
}
