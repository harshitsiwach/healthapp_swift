import Foundation
import Security

public final class PerplexityKeyStore {
    public static let shared = PerplexityKeyStore()
    private let keyIdentifier = "com.healthapp.perplexity.apikey"
    
    private init() {}
    
    public func saveKey(_ key: String) throws {
        guard let data = key.data(using: .utf8) else { return }
        
        // Remove existing key to avoid duplicates
        try deleteKey()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyIdentifier,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeyStoreError.saveFailed(status)
        }
    }
    
    public func getKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyIdentifier,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let data = item as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    public func deleteKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyIdentifier
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeyStoreError.deleteFailed(status)
        }
    }
    
    public var hasKey: Bool {
        return getKey() != nil
    }
}

enum KeyStoreError: Error {
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)
}
