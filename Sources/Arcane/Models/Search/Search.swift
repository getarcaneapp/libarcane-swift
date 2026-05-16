import Foundation

public struct SettingsSearchRequest: Codable, Hashable, Sendable {
    public var query: String

    public init(query: String) {
        self.query = query
    }
}

public struct SettingsSearchResponse: Codable, Hashable, Sendable {
    public var results: [SettingCategory]
    public var query: String
    public var count: Int

    public init(results: [SettingCategory], query: String, count: Int) {
        self.results = results
        self.query = query
        self.count = count
    }
}
