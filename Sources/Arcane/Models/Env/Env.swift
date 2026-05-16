import Foundation

/// EnvVariable is a generic `KEY=value` template variable.
public struct EnvVariable: Codable, Hashable, Sendable {
    public var key: String
    public var value: String

    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

/// EnvVariables wraps a collection of variables for endpoints that accept a `variables` array.
public struct EnvVariables: Codable, Hashable, Sendable {
    public var variables: [EnvVariable]

    public init(variables: [EnvVariable] = []) {
        self.variables = variables
    }
}
