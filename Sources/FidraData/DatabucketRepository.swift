//
//  DatabucketRepository.swift
//  FidraCore
//

import Foundation
import UIKit

public class DatabucketRepository {
    public static let shared = DatabucketRepository()
    private let apiService: ApiServiceProtocol
    private let userDefaultsManager: CacheManagerProtocol
    private let userIdKey = "user_id"
    private let isEnabled: Bool

    private init() {
        self.apiService = ApiServerService(baseUrl: "")
        self.userDefaultsManager = UserDefaultsManager()
        self.isEnabled = false
        ensureUserId()
    }

    public init(apiService: ApiServiceProtocol, cacheManager: CacheManagerProtocol, isEnabled: Bool = true) {
        self.apiService = apiService
        self.userDefaultsManager = cacheManager
        self.isEnabled = isEnabled
        ensureUserId()
    }

    public static func configured(baseUrl: String, apiKey: String) -> DatabucketRepository {
        let service = ApiServerService(baseUrl: baseUrl)
        service.addDefaultHeader(key: "X-API-KEY", value: apiKey)
        return DatabucketRepository(apiService: service, cacheManager: UserDefaultsManager(), isEnabled: true)
    }

    private func ensureUserId() {
        if userDefaultsManager.string(forKey: userIdKey) == nil {
            userDefaultsManager.setValue(UUID().uuidString, forKey: userIdKey)
        }
    }

    public func logEvent(eventName: String, parameters: [String: Any]) async {
        guard isEnabled else { return }
        do {
            let bundleId = Bundle.main.bundleIdentifier ?? ""
            let timestamp = Int(Date().timeIntervalSince1970 * 1000)
            var payload: [String: Any] = await [
                "event_name": eventName,
                "_ts": timestamp,
                "bundle_id": bundleId,
                "user_id": userDefaultsManager.string(forKey: userIdKey) ?? "",
                "device_name": UIDevice.modelName
            ]

            for (key, value) in parameters {
                if key == "session_number", let strValue = value as? String {
                    payload[key] = Int(strValue) ?? 0
                } else {
                    payload[key] = value
                }
            }

            try await apiService.post(
                api: "/push",
                parameters: payload
            )
            print("DEBUG 💚: Gửi sự kiện \(eventName) đến Databucket thành công với timestamp: \(timestamp)")
        } catch {
            print("DEBUG 🧡: Lỗi khi ghi log sự kiện - \(error)")
        }
    }
}
