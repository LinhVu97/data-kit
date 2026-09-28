//
//  IapTrackingRepository.swift
//  FidraData
//
//  Created by hi on 25/2/25.
//

import Foundation
import UIKit

public class IapTrackingRepository: IapTrackingRepositoryProtocol {
    private let apiService: ApiServiceProtocol
    private let cacheManager: CacheManagerProtocol
    private let installDateKey = "iap_install_date"
    
    public init(apiKey: String = "notify_f58ba22b4f8832a_1648636800") {
        let apiService = ApiServerService(baseUrl: "https://stores.volio.vn")
        apiService.addDefaultHeader(key: "X-API-KEY", value: apiKey)
        self.apiService = apiService
        self.cacheManager = UserDefaultsManager()
    }

    public init(baseUrl: String = "https://stores.volio.vn", apiKey: String = "notify_f58ba22b4f8832a_1648636800") {
        let apiService = ApiServerService(baseUrl: baseUrl)
        apiService.addDefaultHeader(key: "X-API-KEY", value: apiKey)
        self.apiService = apiService
        self.cacheManager = UserDefaultsManager()
    }
    
    public init(apiService: ApiServiceProtocol, cacheManager: CacheManagerProtocol? = nil) {
        self.apiService = apiService
        self.cacheManager = cacheManager ?? UserDefaultsManager()
    }
    
    private func getAppName() -> String {
        if let displayName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String {
            return displayName
        }
        return Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
    }
    
    private func toDouble(from value: Any) -> Double? {
        switch value {
        case let v as Double:
            return v
            
        case let v as String:
            return Double(v)
            
        case let v as Decimal:
            return NSDecimalNumber(decimal: v).doubleValue
            
        case let v as NSDecimalNumber:
            return v.doubleValue
            
        case let v as NSNumber:
            return v.doubleValue
            
        default:
            return nil
        }
    }
    
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    
    private func getPlatform() -> String {
        #if os(iOS)
        return "iOS"
        #elseif os(macOS)
        return "macOS"
        #else
        return UIDevice.current.systemName
        #endif
    }

    private func getEstimatedInstallDate() -> Date {
        if let savedDate = cacheManager.date(forKey: installDateKey) {
            return savedDate
        }
        
        let fileManager = FileManager.default
        
        let directories: [FileManager.SearchPathDirectory] = [
            .documentDirectory,
            .libraryDirectory,
            .applicationSupportDirectory
        ]
        
        var dates: [Date] = []
        
        for dir in directories {
            guard let url = fileManager.urls(for: dir, in: .userDomainMask).first else {
                continue
            }
            
            if let creationDate = try? fileManager
                .attributesOfItem(atPath: url.path)[.creationDate] as? Date {
                dates.append(creationDate)
            }
        }
        
        let installDate = dates.min() ?? Date()
        cacheManager.setValue(installDate, forKey: installDateKey)
        
        return installDate
    }
    
    public func trackInitUser(params: [String: Any]) async throws {
        var parameters: [String: Any] = [
            "status": true,
            "app_name": getAppName(),
            "platform": getPlatform(),
            "app_version": getAppVersion(),
            "install_timestamp": Int(getEstimatedInstallDate().timeIntervalSince1970)
        ]
        
        for (key, value) in params {
            if key == "price" {
                if let doubleValue = toDouble(from: value) {
                    parameters[key] = doubleValue
                    continue
                }
            } else {
                parameters[key] = value
            }
        }
        print("DEBUG 💚: Parameters - \(parameters)")
        
        try await apiService.post(
            api: "/stores/api/v5.0/public/apple-users",
            parameters: parameters,
            sendTimeout: 10.0,
            receiveTimeout: 10.0
        )
    }
    
    public func trackPurchaseFailure(params: [String: Any]) async throws {
        var parameters: [String: Any] = [
            "status": false,
            "app_name": getAppName(),
            "platform": getPlatform(),
            "app_version": getAppVersion(),
            "install_timestamp": Int(getEstimatedInstallDate().timeIntervalSince1970)
        ]
        
        for (key, value) in params {
            
            if key == "price" {
                if let doubleValue = toDouble(from: value) {
                    parameters[key] = doubleValue
                    continue
                }
            } else {
                parameters[key] = value
            }
            
        }
        print("DEBUG 💚: Parameters - \(parameters)")
        
        try await apiService.post(
            api: "/stores/api/v5.0/public/apple-users",
            parameters: parameters,
            sendTimeout: 10.0,
            receiveTimeout: 10.0
        )
    }
}

