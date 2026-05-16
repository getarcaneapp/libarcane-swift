import Foundation

public struct PaginatedResponse<T: Decodable & Sendable>: Decodable, Sendable {
    public var success: Bool
    public var data: [T]
    public var pagination: PaginationResponse
}

/// An async sequence that walks a paginated endpoint, fetching successive
/// `limit`-sized pages until `pagination.totalItems` is exhausted.
public struct ArcanePaginator<Element: Decodable & Sendable>: AsyncSequence, Sendable {
    public typealias AsyncIterator = Iterator

    private let limit: Int
    private let fetch: @Sendable (_ start: Int, _ limit: Int) async throws -> PaginatedResponse<Element>

    public init(
        limit: Int = 50,
        fetch: @escaping @Sendable (_ start: Int, _ limit: Int) async throws -> PaginatedResponse<Element>
    ) {
        self.limit = Swift.max(1, limit)
        self.fetch = fetch
    }

    public func makeAsyncIterator() -> Iterator {
        Iterator(limit: limit, fetch: fetch)
    }

    public struct Iterator: AsyncIteratorProtocol {
        private let limit: Int
        private let fetch: @Sendable (_ start: Int, _ limit: Int) async throws -> PaginatedResponse<Element>
        private var start = 0
        private var buffer: [Element] = []
        private var index = 0
        private var finished = false

        init(
            limit: Int,
            fetch: @escaping @Sendable (_ start: Int, _ limit: Int) async throws -> PaginatedResponse<Element>
        ) {
            self.limit = limit
            self.fetch = fetch
        }

        public mutating func next() async throws -> Element? {
            if index < buffer.count {
                defer { index += 1 }
                return buffer[index]
            }
            guard !finished else { return nil }
            let response = try await fetch(start, limit)
            buffer = response.data
            index = 0
            start += response.data.count
            finished = buffer.isEmpty || Int64(start) >= response.pagination.totalItems
            return try await next()
        }
    }
}
