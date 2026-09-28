import Foundation

public protocol CacheManagerProtocol {
    func saveLastFetchTime(for identifier: String)
    func shouldRefreshData(for identifier: String, refreshInterval: Int) -> Bool
    func clearAllFetchTimes()
    
    func string(forKey key: String) -> String?
    func date(forKey key: String) -> Date?
    func setValue(_ value: Any?, forKey key: String)
    
    func getDeviceRegistrationInfo() -> DeviceRegistrationInfo?
    func setDeviceRegistrationInfo(_ info: DeviceRegistrationInfo)
    
    func saveScriptModel(_ script: ScriptModel, forAppId appId: String)
    func getScriptModel(forAppId appId: String) -> ScriptModel?
    func shouldRefreshScriptModel(forAppId appId: String, refreshInterval: Int) -> Bool
}
