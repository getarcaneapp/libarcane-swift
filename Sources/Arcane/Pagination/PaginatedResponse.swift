import Foundation

public struct PaginatedResponse<T: Decodable & Sendable>: Decodable, Sendable {
    public var success: Bool
    public var data: [T]
    public var pagination: PaginationResponse
}

public struct ArcanePaginator<Element: Decodable & Sendable>: AsyncSequence, Sendable {
    public typealias AsyncIterator = Iterator

    private let fetch: @Sendable (Int) async throws -> PaginatedResponse<Element>

    public init(fetch: @escaping @Sendable (Int) async throws -> PaginatedResponse<Element>) {
        self.fetch = fetch
    }

    public func makeAsyncIterator() -> Iterator {
        Iterator(fetch: fetch)
    }

    public struct Iterator: AsyncIteratorProtocol {
        private let fetch: @Sendable (Int) async throws -> PaginatedResponse<Element>
        private var page = 1
        private var buffer: [Element] = []
        private var index = 0
        private var finished = false

        init(fetch: @escaping @Sendable (Int) async throws -> PaginatedResponse<Element>) {
            self.fetch = fetch
        }

        public mutating func next() async throws -> Element? {
            if index < buffer.count {
                defer { index += 1 }
                return buffer[index]
            }
            guard !finished else {
                return nil
            }
            let response = try await fetch(page)
            buffer = response.data
            index = 0
            finished = Int64(page) >= response.pagination.totalPages || buffer.isEmpty
            page += 1
            return try await next()
        }
    }
}
