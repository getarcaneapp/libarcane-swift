import Foundation

extension KeyedDecodingContainer {
  func decodeEmptyDictionaryIfPresent<Value: Decodable>(
    _ type: [String: Value].Type,
    forKey key: Key
  ) throws -> [String: Value] {
    try decodeIfPresent(type, forKey: key) ?? [:]
  }
}
