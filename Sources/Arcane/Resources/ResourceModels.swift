import Foundation

public struct SystemStatsFrame: Codable, Hashable, Sendable {
    public var cpuPercent: Double?
    public var memoryPercent: Double?
    public var raw: [String: JSONValue]?

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        raw = try? container.decode([String: JSONValue].self)
        cpuPercent = raw?["cpuPercent"]?.doubleValue ?? raw?["cpu"]?.doubleValue
        memoryPercent = raw?["memoryPercent"]?.doubleValue ?? raw?["memory"]?.doubleValue
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(raw ?? [:])
    }
}

extension JSONValue {
    var doubleValue: Double? {
        if case let .number(value) = self {
            return value
        }
        return nil
    }
}
