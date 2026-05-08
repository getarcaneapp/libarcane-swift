import Foundation

public struct SystemStatsFrame: Codable, Hashable, Sendable {
    public var cpuPercent: Double?
    public var memoryPercent: Double?
    public var memoryUsageBytes: Int64?
    public var memoryTotalBytes: Int64?
    public var diskUsageBytes: Int64?
    public var diskTotalBytes: Int64?
    public var cpuCount: Int?
    public var hostname: String?
    public var platform: String?
    public var architecture: String?
    public var raw: [String: JSONValue]?

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        raw = try? container.decode([String: JSONValue].self)
        cpuPercent = raw?["cpuPercent"]?.doubleValue ?? raw?["cpu"]?.doubleValue ?? raw?["cpuUsage"]?.doubleValue
        memoryPercent = raw?["memoryPercent"]?.doubleValue ?? raw?["memory"]?.doubleValue
        memoryUsageBytes = raw?["memoryUsage"]?.int64Value
        memoryTotalBytes = raw?["memoryTotal"]?.int64Value
        diskUsageBytes = raw?["diskUsage"]?.int64Value
        diskTotalBytes = raw?["diskTotal"]?.int64Value
        cpuCount = raw?["cpuCount"]?.intValue
        hostname = raw?["hostname"]?.stringValue
        platform = raw?["platform"]?.stringValue
        architecture = raw?["architecture"]?.stringValue

        if memoryPercent == nil, let used = memoryUsageBytes, let total = memoryTotalBytes, total > 0 {
            memoryPercent = (Double(used) / Double(total)) * 100.0
        }
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

    var intValue: Int? {
        if case let .number(value) = self {
            return Int(value)
        }
        return nil
    }

    var int64Value: Int64? {
        if case let .number(value) = self {
            return Int64(value)
        }
        return nil
    }

    var stringValue: String? {
        if case let .string(value) = self {
            return value
        }
        return nil
    }
}
