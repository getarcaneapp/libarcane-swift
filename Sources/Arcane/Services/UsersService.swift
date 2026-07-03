import Foundation

/// UsersService manages user accounts and password changes.
public struct UsersService: Sendable {
  private let rest: RESTService

  init(rest: RESTService) {
    self.rest = rest
  }

  /// List users with pagination.
  public func listPaginated(
    search: String? = nil,
    sort: String? = nil,
    order: SortOrder? = nil,
    start: Int = 0,
    limit: Int = 20
  ) async throws -> PaginatedResponse<User> {
    var query: [URLQueryItem] = []
    if let search { query.append(URLQueryItem(name: "search", value: search)) }
    if let sort { query.append(URLQueryItem(name: "sort", value: sort)) }
    if let order { query.append(URLQueryItem(name: "order", value: order.rawValue)) }
    return try await rest.transport.paginated("users", start: start, limit: limit, query: query)
  }

  /// Get a user by ID.
  public func get(id: String) async throws -> User {
    try await rest.get("users/\(id)")
  }

  /// Create a new user account.
  public func create(_ body: CreateUser) async throws -> User {
    try await rest.post("users", body: body)
  }

  /// Update an existing user.
  public func update(id: String, body: UpdateUser) async throws -> User {
    try await rest.put("users/\(id)", body: body)
  }

  /// Delete a user.
  public func delete(id: String) async throws {
    try await rest.deleteVoid("users/\(id)")
  }

  /// Change the current user's password.
  public func changePassword(_ body: PasswordChange) async throws {
    try await rest.postVoid("auth/password", body: body)
  }

  /// List a user's role assignments (v2 only).
  /// Reserved for global admins server-side.
  public func getRoleAssignments(userId: String) async throws -> [RoleAssignment] {
    try await rest.get("users/\(userId)/role-assignments")
  }

  /// Replace a user's manual role assignments (v2 only).
  /// `source == "oidc"` assignments are preserved by the server.
  /// May throw `.conflict` if the change would remove the last global admin.
  @discardableResult
  public func setRoleAssignments(
    userId: String,
    assignments: [UserAssignmentInput]
  ) async throws -> [RoleAssignment] {
    try await rest.put(
      "users/\(userId)/role-assignments",
      body: SetUserAssignments(assignments: assignments)
    )
  }
}
