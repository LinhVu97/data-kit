//
//  RealtimeSegmentDatabucketsRepository.swift
//  FidraData
//
//  Created by Nguyen anh tuan on 22/5/26.
//

import Foundation
import UIKit

public class RealtimeSegmentDatabucketsRepository {
    private let apiService: ApiServiceProtocol
    private var userId: String
    private var country: String
    private var baseUrl: String
    private var apiKey: String
    
    
    public init(userId: String, country: String, baseUrl: String = "https://hub.databucket.io", apiKey: String = "smXchqbzt3hz40QYxkaplLF6TD5IxphBSE1Gkbq9TD9QXxKJ1oexiKttH7wmgMqd1vHQf7vxXlQA2Nj2bhHkAKqXBFBurw4Uy7FXj7sU0nVr1TBsD97bMS6l3uMtRArQ") {
        let service = ApiServerService(baseUrl: baseUrl)
        service.addDefaultHeader(key: "X-API-KEY", value: apiKey)
        self.apiService = service
        self.userId = userId
        self.country = country
        self.baseUrl = baseUrl
        self.apiKey = apiKey
    }
    
    // hàm khởi tạo segment, gán variant cho user
    public func initSegmentByUserId<T: Decodable>(
        api: String = "/eval?",
        rule: String,
        extraParams: [String: Any] = [:],
        sendTimeout: TimeInterval = 5.0,
        receiveTimeout: TimeInterval = 5.0
    ) async -> T? {
        var params: [String: Any] = [
            "rule": rule,
            "uid": self.userId,
            "country": self.country,
        ]
        for (key, value) in extraParams {
            params[key] = value
        }
        do {
            let res: T = try await apiService.get(
                api: api,
                parameters: params,
                isBaseResponse: false,
                sendTimeout: sendTimeout,
                receiveTimeout: receiveTimeout
            )
            return res
        } catch {
            print("initSegmentByUserId ❌ error \(error.localizedDescription)")
            return nil
        }
    }
    
    // hàm lấy ra kịch bản test của user theo userId
    public func getScenarioByUserId<T: Decodable>(
        api: String = "/eval?",
        rule: String,
        extraParams: [String: Any] = [:],
        sendTimeout: TimeInterval = 5.0,
        receiveTimeout: TimeInterval = 5.0
    ) async -> T? {
        var params: [String: Any] = [
            "rule": rule,
            "uid": self.userId,
        ]
        for (key, value) in extraParams {
            params[key] = value
        }
        do {
            let res: T = try await apiService.get(
                api: api,
                parameters: params,
                isBaseResponse: false,
                sendTimeout: sendTimeout,
                receiveTimeout: receiveTimeout
            )
            return res
        } catch {
            return nil
        }
    }
}
