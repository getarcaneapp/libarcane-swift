import Foundation

public struct APIResponse<T: Decodable & Sendable>: Decodable, Sendable {
    public var success: Bool
    public var data: T
}
