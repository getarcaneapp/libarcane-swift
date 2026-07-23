import Foundation

/// A manager-owned variable that is materialized into one or more environments.
/// Secret values are redacted by the server when read.
public struct GlobalVariable: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var key: String
  public var value: String
  public var isSecret: Bool
  public var allEnvironments: Bool
  public var environmentIDs: [String]
  public var createdAt: Date
  public var updatedAt: Date?

  public enum CodingKeys: String, CodingKey {
    case id, key, value, isSecret, allEnvironments, createdAt, updatedAt
    case environmentIDs = "environmentIds"
  }

  public init(
    id: String,
    key: String,
    value: String,
    isSecret: Bool = false,
    allEnvironments: Bool = false,
    environmentIDs: [String] = [],
    createdAt: Date,
    updatedAt: Date? = nil
  ) {
    self.id = id
    self.key = key
    self.value = value
    self.isSecret = isSecret
    self.allEnvironments = allEnvironments
    self.environmentIDs = environmentIDs
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    key = try container.decode(String.self, forKey: .key)
    value = try container.decodeIfPresent(String.self, forKey: .value) ?? ""
    isSecret = try container.decodeIfPresent(Bool.self, forKey: .isSecret) ?? false
    allEnvironments =
      try container.decodeIfPresent(Bool.self, forKey: .allEnvironments) ?? false
    environmentIDs =
      try container.decodeIfPresent([String].self, forKey: .environmentIDs) ?? []
    createdAt = try container.decode(Date.self, forKey: .createdAt)
    updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
  }
}

public struct CreateGlobalVariableRequest: Codable, Hashable, Sendable {
  public var key: String
  public var value: String
  public var isSecret: Bool
  public var allEnvironments: Bool
  public var environmentIDs: [String]

  public enum CodingKeys: String, CodingKey {
    case key, value, isSecret, allEnvironments
    case environmentIDs = "environmentIds"
  }

  public init(
    key: String,
    value: String,
    isSecret: Bool = false,
    allEnvironments: Bool = false,
    environmentIDs: [String] = []
  ) {
    self.key = key
    self.value = value
    self.isSecret = isSecret
    self.allEnvironments = allEnvironments
    self.environmentIDs = environmentIDs
  }
}

/// Partial update. A nil value preserves the current field; an empty
/// `environmentIDs` array explicitly clears environment-specific scope.
public struct UpdateGlobalVariableRequest: Codable, Hashable, Sendable {
  public var key: String?
  public var value: String?
  public var isSecret: Bool?
  public var allEnvironments: Bool?
  public var environmentIDs: [String]?

  public enum CodingKeys: String, CodingKey {
    case key, value, isSecret, allEnvironments
    case environmentIDs = "environmentIds"
  }

  public init(
    key: String? = nil,
    value: String? = nil,
    isSecret: Bool? = nil,
    allEnvironments: Bool? = nil,
    environmentIDs: [String]? = nil
  ) {
    self.key = key
    self.value = value
    self.isSecret = isSecret
    self.allEnvironments = allEnvironments
    self.environmentIDs = environmentIDs
  }
}

/// Current materialization state for a manager-owned variable in an environment.
/// Unknown server values are preserved so newer backends remain decodable.
public enum VariableSyncState: Hashable, Sendable, RawRepresentable, Codable {
  case synced
  case pending
  case error
  case unknown(String)

  public init?(rawValue: String) {
    switch rawValue {
    case "synced": self = .synced
    case "pending": self = .pending
    case "error": self = .error
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .synced: "synced"
    case .pending: "pending"
    case .error: "error"
    case .unknown(let value): value
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self = VariableSyncState(rawValue: try container.decode(String.self)) ?? .unknown("")
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

public struct EnvironmentSyncStatus: Codable, Hashable, Sendable, Identifiable {
  public var environmentID: String
  public var environmentName: String?
  public var status: VariableSyncState
  public var error: String?
  public var lastSyncedAt: Date?

  public var id: String { environmentID }

  public enum CodingKeys: String, CodingKey {
    case environmentID = "environmentId"
    case environmentName, status, error, lastSyncedAt
  }

  public init(
    environmentID: String,
    environmentName: String? = nil,
    status: VariableSyncState,
    error: String? = nil,
    lastSyncedAt: Date? = nil
  ) {
    self.environmentID = environmentID
    self.environmentName = environmentName
    self.status = status
    self.error = error
    self.lastSyncedAt = lastSyncedAt
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    environmentID = try container.decode(String.self, forKey: .environmentID)
    environmentName = try container.decodeIfPresent(String.self, forKey: .environmentName)
    status = try container.decodeIfPresent(VariableSyncState.self, forKey: .status) ?? .unknown("")
    error = try container.decodeIfPresent(String.self, forKey: .error)
    lastSyncedAt = try container.decodeIfPresent(Date.self, forKey: .lastSyncedAt)
  }
}

public struct GlobalVariableMutationResponse: Codable, Hashable, Sendable {
  public var variable: GlobalVariable?
  public var syncResults: [EnvironmentSyncStatus]

  public init(
    variable: GlobalVariable? = nil,
    syncResults: [EnvironmentSyncStatus] = []
  ) {
    self.variable = variable
    self.syncResults = syncResults
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    variable = try container.decodeIfPresent(GlobalVariable.self, forKey: .variable)
    syncResults =
      try container.decodeIfPresent([EnvironmentSyncStatus].self, forKey: .syncResults) ?? []
  }
}
