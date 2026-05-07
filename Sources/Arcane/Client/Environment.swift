import Foundation

public struct EnvironmentID: RawRepresentable, ExpressibleByStringLiteral, Codable, Hashable, Sendable {
    public static let localDocker: EnvironmentID = "0"

    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: StringLiteralType) {
        self.rawValue = value
    }
}

public struct RetryPolicy: Sendable {
    public var maxAttempts: Int
    public var baseBackoff: Duration
    public var maxBackoff: Duration

    public static let `default` = RetryPolicy(
        maxAttempts: 3,
        baseBackoff: .milliseconds(150),
        maxBackoff: .seconds(2)
    )

    public init(maxAttempts: Int, baseBackoff: Duration, maxBackoff: Duration) {
        self.maxAttempts = max(1, maxAttempts)
        self.baseBackoff = baseBackoff
        self.maxBackoff = maxBackoff
    }
}
