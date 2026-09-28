//
//  DeviceServices.swift
//  FidraData
//
//  Created by hi on 22/8/25.
//

import UIKit

public class DeviceServices {
    // Singleton instance
    public static let shared = DeviceServices()
    
    private let keychainKey = "com.volio.global.govo.mobile_device_identifier/device_id"
    private var cachedDeviceId: String?
    
    // Private initializer to prevent external instantiation
    private init() {
        self.cachedDeviceId = loadDeviceIdentifier()
    }
    
    // Public method to get device ID
    public func getDeviceId() -> String {
        return cachedDeviceId ?? generateAndStoreDeviceId()
    }
    
    // Private method to load device ID from Keychain
    private func loadDeviceIdentifier() -> String? {
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    // Private method to generate and store a new device ID
    private func generateAndStoreDeviceId() -> String {
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecValueData as String: deviceId.data(using: .utf8)!
        ]
        
        SecItemDelete(keychainQuery as CFDictionary) // Delete any existing item
        SecItemAdd(keychainQuery as CFDictionary, nil)
        
        cachedDeviceId = deviceId
        return deviceId
    }
    
    // Optional: Method to clear device ID from Keychain
    public func clearDeviceId() {
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey
        ]
        
        SecItemDelete(keychainQuery as CFDictionary)
        cachedDeviceId = nil
    }
}
