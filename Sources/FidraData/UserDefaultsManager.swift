//
//  UserDefaultsManager.swift
//  FidraData
//
//  Created by Fidra Core Team
//

import Foundation

public class UserDefaultsManager: CacheManagerProtocol {
    
    public init() {}
    
    // MARK: - Khóa cấu hình
    public struct Keys {
        // Tiền tố cho các khóa lưu thời gian lấy dữ liệu
        public static let lastFetchPrefix = "lastFetch_"
    }
    
    // Lưu giá trị
    public func setValue(_ value: Any?, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    // Lấy giá trị theo loại
    public func getValue<T>(forKey key: String) -> T? {
        return UserDefaults.standard.object(forKey: key) as? T
    }
    
    public func string(forKey key: String) -> String? {
        return UserDefaults.standard.string(forKey: key)
    }
    
    public func int(forKey key: String) -> Int {
        return UserDefaults.standard.integer(forKey: key)
    }
    
    public func bool(forKey key: String) -> Bool {
        return UserDefaults.standard.bool(forKey: key)
    }
    
    public func dictionary(forKey key: String) -> [String: Any]? {
        return UserDefaults.standard.dictionary(forKey: key)
    }
    
    public func array(forKey key: String) -> [Any]? {
        return UserDefaults.standard.array(forKey: key)
    }
    
    public func date(forKey key: String) -> Date? {
        return UserDefaults.standard.object(forKey: key) as? Date
    }
    
    public func data(forKey key: String) -> Data? {
        return UserDefaults.standard.data(forKey: key)
    }
    
    // Kiểm tra tồn tại
    public func hasValue(forKey key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
    
    // Xóa giá trị
    public func removeValue(forKey key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    // Xóa tất cả giá trị có tiền tố nhất định
    public func removeAllValues(withPrefix prefix: String) {
        UserDefaults.standard.dictionaryRepresentation().keys.forEach { key in
            if key.hasPrefix(prefix) {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
    
    // MARK: - Các phương thức tiện ích cho tác vụ lấy dữ liệu
    
    // Lưu thời gian lấy dữ liệu
    public func saveLastFetchTime(for identifier: String) {
        let currentTime = Int(Date().timeIntervalSince1970)
        setValue(currentTime, forKey: Keys.lastFetchPrefix + identifier)
    }
    
    // Kiểm tra nếu dữ liệu cần được làm mới (sau một khoảng thời gian)
    public func shouldRefreshData(for identifier: String, refreshInterval: Int = 60) -> Bool {
        let lastFetchKey = Keys.lastFetchPrefix + identifier
        let lastFetchTime = int(forKey: lastFetchKey)
        let currentTime = Int(Date().timeIntervalSince1970)
        
        return currentTime - lastFetchTime > refreshInterval
    }

    public func setFcmToken(_ token: String) {
        setValue(token, forKey: "fcm_token")
    }

    public func getFcmToken() -> String? {
        return string(forKey: "fcm_token")
    }
    
    // MARK: - Device Registration Info Management
    
    public func setDeviceRegistrationInfo(_ info: DeviceRegistrationInfo) {
        if let data = try? JSONEncoder().encode(info) {
            setValue(data, forKey: "device_registration_info")
        }
    }
    
    public func getDeviceRegistrationInfo() -> DeviceRegistrationInfo? {
        guard let data = data(forKey: "device_registration_info") else { return nil }
        return try? JSONDecoder().decode(DeviceRegistrationInfo.self, from: data)
    }
    
    // MARK: - Script Model Management
    
    public func saveScriptModel(_ script: ScriptModel, forAppId appId: String) {
        if let data = try? JSONEncoder().encode(script) {
            setValue(data, forKey: "script_model_\(appId)")
            saveLastFetchTime(for: "script_\(appId)")
        }
    }
    
    public func getScriptModel(forAppId appId: String) -> ScriptModel? {
        guard let data = data(forKey: "script_model_\(appId)") else { return nil }
        return try? JSONDecoder().decode(ScriptModel.self, from: data)
    }
    
    public func shouldRefreshScriptModel(forAppId appId: String, refreshInterval: Int) -> Bool {
        return shouldRefreshData(for: "script_\(appId)", refreshInterval: refreshInterval)
    }
    
    // Xóa tất cả các khóa lưu thời gian lấy dữ liệu
    public func clearAllFetchTimes() {
        removeAllValues(withPrefix: Keys.lastFetchPrefix)
    }
}

@propertyWrapper
public struct UserDefault<T> {
    let key: String
    let defaultValue: T?
    
    let userDefaultsManager = UserDefaultsManager()
    
    public init(key: String, defaultValue: T? = nil) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    public var wrappedValue: T {
        get {
            userDefaultsManager.getValue(forKey: key) ?? defaultValue as! T
        }
        set {
            userDefaultsManager.setValue(newValue, forKey: key)
        }
    }
}
