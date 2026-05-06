import Foundation
import Security

public struct KeychainTokenStore: TokenStore {
    public var service: String
    public var account: String
    public var accessGroup: String?

    public init(service: String, account: String = "default", accessGroup: String? = nil) {
        self.service = service
        self.account = account
        self.accessGroup = accessGroup
    }

    public func loadTokens() async throws -> TokenPair? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
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
        let data = try JSONEncoder().encode(tokens)
        var query = baseQuery()
        let attributes = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            query[kSecValueData as String] = data
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
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError(status: status)
        }
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
