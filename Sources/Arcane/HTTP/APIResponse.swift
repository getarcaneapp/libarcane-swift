import Foundation

public struct APIResponse<T: Decodable & Sendable>: Decodable, Sendable {
  public var success: Bool
  public var data: T
}

public struct PaginatedAPIResponse<T: Decodable & Sendable>: Decodable, Sendable {
  public var success: Bool
  public var data: [T]
  public var pagination: PaginationResponse
}
