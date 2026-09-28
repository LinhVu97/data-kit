import Foundation
import UIKit

public class RatingRepository {
    public static let shared = RatingRepository()
    private let apiService: ApiServiceProtocol
    private let userDefault: CacheManagerProtocol
    
    private init() {
        let service = ApiServerService(baseUrl: "https://reporter.volio.vn")
        service.addDefaultHeader(key: "X-API-KEY", value: "reporter_f58ba22b4f8832a_1648636800")
        self.apiService = service
        self.userDefault = UserDefaultsManager()
    }
    
    public init(apiService: ApiServiceProtocol, cacheManager: CacheManagerProtocol) {
        self.apiService = apiService
        self.userDefault = cacheManager
    }
    
    private func getDeviceInfo(userId: String? = nil) -> DeviceRegistrationInfo{
        let deviceId =  DeviceServices.shared.getDeviceId()
        let bundleId = Bundle.main.bundleIdentifier
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let languageCode = Locale.current.languageCode ?? ""
        let countryCode = Locale.current.regionCode ?? ""
        let deviceType =  UIDevice.modelName
        let os =  UIDevice.current.systemName
        let osVersion =  UIDevice.current.systemVersion

        
        let deviceInfo = DeviceRegistrationInfo(
            deviceId: deviceId,
            bundleId: bundleId ?? "",
            version: version,
            userId: userId,
            languageCode: languageCode,
            countryCode: countryCode,
            deviceType: deviceType,
            os: os,
            token: "",
            osVersion: osVersion
        )
        
        return deviceInfo
    }
    
    public func registerDevice(
        appId: String,
        userId: String? = nil
    ) async throws {
        // Tạo một đối tượng để lưu trữ thông tin thiết bị
        let deviceInfo = getDeviceInfo()
        
        // Kiểm tra xem thông tin đã thay đổi so với lần đăng ký trước đó chưa
        let lastInfo = userDefault.getDeviceRegistrationInfo()
        var shouldRegister = true
        
        if let lastInfo = lastInfo {
            // Chỉ gửi yêu cầu nếu có thay đổi thông tin
            shouldRegister = lastInfo.deviceId != deviceInfo.deviceId || 
                             lastInfo.bundleId != deviceInfo.bundleId || 
                             lastInfo.version != deviceInfo.version ||
                             lastInfo.languageCode != deviceInfo.languageCode || 
                             lastInfo.countryCode != deviceInfo.countryCode ||
                             lastInfo.token != deviceInfo.token ||
                             lastInfo.osVersion != deviceInfo.osVersion
        }
        
        if shouldRegister {
            let parameters: [String: Any] = [
                "app_id": appId,
                "bundle_id": deviceInfo.bundleId,
                "country_code": deviceInfo.countryCode,
                "device_id": deviceInfo.deviceId,
                "device_type": deviceInfo.deviceType,
                "language_code": deviceInfo.languageCode,
                "os": deviceInfo.os,
                "os_version": deviceInfo.osVersion,
                "user_id": deviceInfo.userId ?? "",
                "version": deviceInfo.version,
                "token": deviceInfo.token ?? ""
            ]
            
            try await apiService.post(
                api: "/api/v1/mobile/devices",
                parameters: parameters
            )
            // Lưu lại toàn bộ đối tượng thông tin thiết bị
            userDefault.setDeviceRegistrationInfo(deviceInfo)
            print("📱 ✅ Device registered")
        } else {
            print("📱 ✅ Device already registered")
        }
    }
    
    public func getScripts(
        appId: String,
        sendTimeout: TimeInterval = 10.0,
        receiveTimeout: TimeInterval = 10.0,
        refreshInterval: Int = 300 // 5 minutes default refresh interval
    ) async throws -> ScriptModel? {
        // Kiểm tra cache trước khi gọi API
       if let cachedScript = userDefault.getScriptModel(forAppId: appId),
          !userDefault.shouldRefreshScriptModel(forAppId: appId, refreshInterval: refreshInterval) { // 5 minutes default refresh interval
           print("📜 ✅ Lấy script từ cache")
           
           return cachedScript
       }
        
        print("📜 🔄 Lấy script từ API")

        let parameters: [String: Any] = await [
            "app_id": appId,
            "bundle_id": Bundle.main.bundleIdentifier ?? "",
            "country_code": Locale.current.regionCode ?? "",
            "device_type": UIDevice.modelName,
            "language_code": Locale.current.languageCode ?? "",
            "os": UIDevice.current.systemName,
            "os_version": UIDevice.current.systemVersion,
            "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        ]
        
        let script: ScriptModel? = try await apiService.get(
            api: "/api/v1/mobile/scripts",
            parameters: parameters,
            sendTimeout: sendTimeout,
            receiveTimeout: receiveTimeout
        )
        
        // Lưu script vào cache nếu có dữ liệu trả về
        if let script = script {
              userDefault.saveScriptModel(script, forAppId: appId)
            print("📜 💾 Đã lưu script vào cache")
        }
        
        return script
    }

    public func sendFeedback(
        appId: String,
        star: Int,
        scriptId: String,
        dialogId: String? = nil,
        attachments: [String]? = nil,
        otherProblem: String? = nil,
        problemIds: [String]? = nil
    ) async throws {
        let deviceInfo = getDeviceInfo()
        // Tạo device info dictionary riêng biệt
        let deviceInfoDict: [String: String] = [
            "country_code": deviceInfo.countryCode,
            "device_id": deviceInfo.deviceId,
            "device_token": deviceInfo.token ?? "",
            "device_type": deviceInfo.deviceType,
            "language_code": deviceInfo.languageCode,
            "os": deviceInfo.os,
            "os_version": deviceInfo.osVersion,
            "user_id": deviceInfo.userId ?? "",
            "version": deviceInfo.version
        ]
        
        // Tạo parameters dictionary với device info đã được tách riêng
        var parameters: [String: Any] = [
            "app_id": appId,
            "script_id": scriptId,
            "star": star,
            "bundle_id": Bundle.main.bundleIdentifier ?? "",
            "device_id": DeviceServices.shared.getDeviceId(),
            "device_info": deviceInfoDict
        ]
        
        // Thêm các tham số tùy chọn nếu có
        if let attachments = attachments {
            parameters["attachments"] = attachments
        }      
        
        if let dialogId = dialogId {
            parameters["dialog_id"] = dialogId
        }
        
        if let otherProblem = otherProblem {
            parameters["other_problem"] = otherProblem
        }
        
        if let problemIds = problemIds {
            parameters["problem_id"] = problemIds
        }
        
        do {
            try await apiService.post(
                api: "/api/v1/mobile/feedbacks",
                parameters: parameters
            )
            print("📱 ✅ Feedback sent")
        } catch {
            print("📱 ❌ Feedback error: \(error)")
            throw error
        }
    }
}
