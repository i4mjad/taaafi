import Foundation
import Security
import UIKit

/// Provides a device ID that persists across app uninstall/reinstall via iOS Keychain.
/// Falls back to IDFV if Keychain operations fail.
@MainActor
final class PersistentDeviceIdService {

    static let shared = PersistentDeviceIdService()

    private static let keychainService = "com.amjadkhalfan.reboot_app_3.deviceid"
    private static let keychainAccount = "persistent_device_id"

    private var cachedDeviceId: String?

    private init() {}

    /// Get the persistent device ID. Never throws.
    func getDeviceId() -> String {
        if let cached = cachedDeviceId {
            return cached
        }

        let deviceId = loadOrCreateDeviceId()
        cachedDeviceId = deviceId
        return deviceId
    }

    // MARK: - Keychain Operations

    private func loadOrCreateDeviceId() -> String {
        // Try reading from Keychain first
        if let stored = readFromKeychain() {
            return stored
        }

        // Generate new UUID and store in Keychain
        let newId = UUID().uuidString
        if saveToKeychain(newId) {
            return newId
        }

        // Fallback to IDFV if Keychain fails
        return UIDevice.current.identifierForVendor?.uuidString ?? "ios_\(UUID().uuidString)"
    }

    private func readFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    private func saveToKeychain(_ value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Delete any existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }
}
