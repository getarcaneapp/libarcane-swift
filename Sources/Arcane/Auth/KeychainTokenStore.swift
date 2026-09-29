import Foundation
import Security

public struct KeychainTokenStore: TokenStore {
  public var service: String
  public var account: String
  public var accessGroup: String?
  private let isCurrent: @Sendable () -> Bool

  /// `validating` is evaluated at the Keychain boundary, after any async
  /// executor hop. Retired sessions cannot read or mutate a replacement account.
  public init(
    service: String,
    account: String = "default",
    accessGroup: String? = nil,
    validating: @escaping @Sendable () -> Bool = { true }
  ) {
    self.service = service
    self.account = account
    self.accessGroup = accessGroup
    self.isCurrent = validating
  }

  public func loadTokens() async throws -> TokenPair? {
    var query = baseQuery()
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne

    var result: CFTypeRef?
    try checkSession()
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    try checkSession()
    if status == errSecItemNotFound {
      return nil
    }
    guard status == errSecSuccess else {
      throw KeychainError(status: status)
    }
    guard let data = result as? Data else {
      return nil
    }
    return try JSONDecoder().decode(TokenPair.self, from: data)
  }

  public func saveTokens(_ tokens: TokenPair) async throws {
    try checkSession()
    let data = try JSONEncoder().encode(tokens)
    try checkSession()
    var query = baseQuery()
    // Keep tokens readable while the device is locked (after the first unlock
    // following a reboot) so a locked device never costs the user their
    // session. `loadTokens`/`clearTokens` don't filter on accessibility, so
    // items saved under the old default migrate to this on the next save.
    let attributes: [String: Any] = [
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
    ]
    try checkSession()
    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if status == errSecItemNotFound {
      query[kSecValueData as String] = data
      query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
      try checkSession()
      let addStatus = SecItemAdd(query as CFDictionary, nil)
      guard addStatus == errSecSuccess else {
        throw KeychainError(status: addStatus)
      }
      return
    }
    guard status == errSecSuccess else {
      throw KeychainError(status: status)
    }
  }

  public func clearTokens() async throws {
    try checkSession()
    let status = SecItemDelete(baseQuery() as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainError(status: status)
    }
  }

  private func checkSession() throws {
    guard isCurrent() else { throw CancellationError() }
  }

  private func baseQuery() -> [String: Any] {
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
    if let accessGroup {
      query[kSecAttrAccessGroup as String] = accessGroup
    }
    return query
  }
}

public struct KeychainError: Error, Equatable, Sendable {
  public var status: OSStatus

  public init(status: OSStatus) {
    self.status = status
  }
}
