import Foundation
import Security

/// Thin wrapper around the iOS/macOS Keychain for storing sensitive strings.
///
/// Used for the API key override entered in parent settings.
/// The bundled Config.plist key is read by ConfigProvider; this stores
/// the optional runtime override only.
actor KeychainService {

    static let shared = KeychainService()

    private let service = "com.sayitright.app"

    // MARK: - API Key

    private let apiKeyAccount = "anthropic-api-key-override"

    func saveAPIKey(_ key: String) throws {
        try save(key, account: apiKeyAccount)
    }

    func retrieveAPIKey() -> String? {
        retrieve(account: apiKeyAccount)
    }

    func deleteAPIKey() throws {
        try delete(account: apiKeyAccount)
    }

    // MARK: - Parent PIN

    private let pinAccount = "parent-pin"

    func savePIN(_ pin: String) throws {
        try save(pin, account: pinAccount)
    }

    func retrievePIN() -> String? {
        retrieve(account: pinAccount)
    }

    func deletePIN() throws {
        try delete(account: pinAccount)
    }

    // MARK: - Generic Keychain Operations

    private func save(_ value: String, account: String) throws {
        let data = Data(value.utf8)

        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    private func retrieve(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

enum KeychainError: Error, LocalizedError {
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let s):  "Keychain save failed (status \(s))"
        case .deleteFailed(let s): "Keychain delete failed (status \(s))"
        }
    }
}
