import Foundation

public struct PaginationResponse: Codable, Hashable, Sendable {
    public var totalPages: Int64
    public var totalItems: Int64
    public var currentPage: Int
    public var itemsPerPage: Int
    public var grandTotalItems: Int64?

    public init(
        totalPages: Int64,
        totalItems: Int64,
        currentPage: Int,
        itemsPerPage: Int,
        grandTotalItems: Int64? = nil
    ) {
        self.totalPages = totalPages
        self.totalItems = totalItems
        self.currentPage = currentPage
        self.itemsPerPage = itemsPerPage
        self.grandTotalItems = grandTotalItems
    }
}

/// Common query parameters for Arcane list endpoints that support search, sort,
/// and offset-based pagination (`start` / `limit`).
public struct SearchPaginationSort: Sendable {
    public var search: String?
    public var start: Int?
    public var limit: Int?
    public var sortBy: String?
    public var sortOrder: SortOrder?

    public init(
        search: String? = nil,
        start: Int? = nil,
        limit: Int? = nil,
        sortBy: String? = nil,
        sortOrder: SortOrder? = nil
    ) {
        self.search = search
        self.start = start
        self.limit = limit
        self.sortBy = sortBy
        self.sortOrder = sortOrder
    }

    public var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let search { items.append(URLQueryItem(name: "search", value: search)) }
        if let start { items.append(URLQueryItem(name: "start", value: "\(start)")) }
        if let limit { items.append(URLQueryItem(name: "limit", value: "\(limit)")) }
        if let sortBy { items.append(URLQueryItem(name: "sort", value: sortBy)) }
        if let sortOrder { items.append(URLQueryItem(name: "order", value: sortOrder.rawValue)) }
        return items
    }

    /// `queryItems` minus the pagination fields. Use this when the `start` and
    /// `limit` are passed as explicit arguments to `rest.paginated(...)` to
    /// avoid duplicate query parameters on the wire.
    public var nonPaginationQueryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let search { items.append(URLQueryItem(name: "search", value: search)) }
        if let sortBy { items.append(URLQueryItem(name: "sort", value: sortBy)) }
        if let sortOrder { items.append(URLQueryItem(name: "order", value: sortOrder.rawValue)) }
        return items
    }
}

public enum SortOrder: String, Codable, Hashable, Sendable {
    case ascending = "asc"
    case descending = "desc"
}
