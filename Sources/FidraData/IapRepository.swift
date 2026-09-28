//
//  IapRepository.swift
//  FidraCore
//
//  Created by hi on 25/2/25.
//

import Foundation

public class IapRepository {
    private let apiService: ApiServiceProtocol
    
    public init() {
        self.apiService = ApiServerService(baseUrl: "https://purchaser.ios.volio.vn/purchaser/api/v1.0")
    }
    
    public init(apiService: ApiServiceProtocol) {
        self.apiService = apiService
    }
    
    
    public func getCurrentTime() async throws -> TimeInterval {
        do {
            let response: TimeInterval = try await apiService.get(
                api: "/receipt/time",
                sendTimeout: 3,
                receiveTimeout: 3
            )
            return response
        } catch {
            print("DEBUG 🧡: Error getting current time - \(error)")
            return Date().timeIntervalSince1970
        }
    }
}
