//
//  ApiService.swift
//  FidraCore
//
//  Created by hi on 24/2/25.
//

import Foundation

open class ApiServerService: ApiServiceProtocol {
    private let baseUrl: String
    private var defaultHeaders: [String: String] = [:]
    
    public init(baseUrl: String = "") {
        self.baseUrl = baseUrl
    }

    private func requireBaseUrl() throws {
        guard !baseUrl.isEmpty else {
            throw ApiError.invalidResponse
        }
    }
    
    open func setDefaultHeaders(_ headers: [String: String]) {
        self.defaultHeaders = headers
    }
    
    open func addDefaultHeader(key: String, value: String) {
        self.defaultHeaders[key] = value
    }
    
    open func get<T: Decodable>(
        api: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        isBaseResponse: Bool = true,
        sendTimeout: TimeInterval =  5.0,
        receiveTimeout: TimeInterval =  5.0
    ) async throws -> T {
        try requireBaseUrl()
        var urlComponents = URLComponents(string: baseUrl + api)
        
        if let parameters = parameters {
            urlComponents?.queryItems = parameters.map {
                URLQueryItem(name: $0.key, value: "\($0.value)")
            }
        }
        
        guard let url = urlComponents?.url else {
            throw ApiError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = sendTimeout
        
        // Áp dụng default headers
        for (key, value) in defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Áp dụng headers được truyền vào (ghi đè default headers nếu trùng)
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ApiError.invalidResponse
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                let errorString = String(data: data, encoding: .utf8) ?? "Không thể đọc dữ liệu lỗi"
                print("❌ Lỗi từ server: Mã \(httpResponse.statusCode), Nội dung: \(errorString)")
                throw ApiError.serverError(httpResponse.statusCode, String(data: data, encoding: .utf8) ?? "")
            }
            
            let decoder = JSONDecoder()
            if isBaseResponse {
                let baseResponse = try decoder.decode(BaseResponse<T>.self, from: data)
                if let responseData = baseResponse.data {
                    return responseData
                }
                throw ApiError.invalidResponse
            } else {
                return try decoder.decode(T.self, from: data)
            }
            
        } catch let error as DecodingError {
            print("❌ Lỗi giải mã dữ liệu: \(error)")
            throw ApiError.decodingError(error)
        } catch {
            print("❌ Lỗi mạng: \(error)")
            throw ApiError.networkError(error)
        }
    }
    
    open func post<T: Decodable>(
        api: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        isBaseResponse: Bool = true,
        sendTimeout: TimeInterval =  5.0,
        receiveTimeout: TimeInterval =  5.0
    ) async throws -> T {
        try requireBaseUrl()
        guard let url = URL(string: baseUrl + api) else {
            throw ApiError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = sendTimeout
        
        // Áp dụng default headers
        for (key, value) in defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Thêm headers vào request (ghi đè default headers nếu trùng)
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        if let parameters = parameters {
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            // ✅ Log raw string JSON
            if let jsonString = String(data: data, encoding: .utf8) {
                print("✅ JSON Raw : \n\(jsonString)")
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ApiError.invalidResponse
            }
            
            
            
            if !(200...299).contains(httpResponse.statusCode) {
                let errorString = String(data: data, encoding: .utf8) ?? "Không thể đọc dữ liệu lỗi"
                print("❌ Lỗi từ server: Mã \(httpResponse.statusCode), Nội dung: \(errorString)")
                throw ApiError.serverError(httpResponse.statusCode, String(data: data, encoding: .utf8) ?? "")
            }
            
            if T.self == Void.self {
                return () as! T
            }
            let decoder = JSONDecoder()
            if isBaseResponse {
                let baseResponse = try decoder.decode(BaseResponse<T>.self, from: data)
                if let responseData = baseResponse.data {
                    return responseData
                }
                
                if baseResponse.data == nil {
                    throw ApiError.serverError(baseResponse.status, baseResponse.message)
                }
                throw ApiError.invalidResponse
            } else {
                return try decoder.decode(T.self, from: data)
            }
            
        } catch let error as DecodingError {
            print("❌ Lỗi giải mã dữ liệu: \(error)")
            throw ApiError.decodingError(error)
        } catch {
            throw ApiError.networkError(error)
        }
    }
    
    open func post(
        api: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        isBaseResponse: Bool = true,
        sendTimeout: TimeInterval =  5.0,
        receiveTimeout: TimeInterval =  5.0
    ) async throws {
        try requireBaseUrl()
        guard let url = URL(string: baseUrl + api) else {
            throw ApiError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = sendTimeout
        
        // Áp dụng default headers
        for (key, value) in defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
            print("====== key \(key) \(value)")
        }
        
        // Thêm headers vào request (ghi đè default headers nếu trùng)
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
                print("====== key \(key) \(value)")
            }
        }
        
        if let parameters = parameters {
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ApiError.invalidResponse
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                let errorString = String(data: data, encoding: .utf8) ?? "Không thể đọc dữ liệu lỗi"
                print("❌ Lỗi từ server: Mã \(httpResponse.statusCode), Nội dung: \(errorString)")
                throw ApiError.serverError(httpResponse.statusCode, String(data: data, encoding: .utf8) ?? "")
            }
            
        } catch let error {
            throw ApiError.networkError(error)
        }
    }
    
    open func put<T: Decodable>(
        api: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        isBaseResponse: Bool = true,
        sendTimeout: TimeInterval =  5.0,
        receiveTimeout: TimeInterval =  5.0
    ) async throws -> T {
        try requireBaseUrl()
        guard let url = URL(string: baseUrl + api) else {
            throw ApiError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.timeoutInterval = sendTimeout
        
        // Áp dụng default headers
        for (key, value) in defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Thêm headers vào request (ghi đè default headers nếu trùng)
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        if let parameters = parameters {
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ApiError.invalidResponse
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                let errorString = String(data: data, encoding: .utf8) ?? "Không thể đọc dữ liệu lỗi"
                print("❌ Lỗi từ server: Mã \(httpResponse.statusCode), Nội dung: \(errorString)")
                throw ApiError.serverError(httpResponse.statusCode, String(data: data, encoding: .utf8) ?? "")
            }
            
            if T.self == Void.self {
                return () as! T
            }
            let decoder = JSONDecoder()
            if isBaseResponse {
                let baseResponse = try decoder.decode(BaseResponse<T>.self, from: data)
                if let responseData = baseResponse.data {
                    return responseData
                }
                throw ApiError.invalidResponse
            } else {
                return try decoder.decode(T.self, from: data)
            }
            
        } catch let error as DecodingError {
            print("❌ Lỗi giải mã dữ liệu: \(error)")
            throw ApiError.decodingError(error)
        } catch {
            throw ApiError.networkError(error)
        }
    }
    
    open func put(
        api: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        isBaseResponse: Bool = true,
        sendTimeout: TimeInterval =  5.0,
        receiveTimeout: TimeInterval =  5.0
    ) async throws {
        try requireBaseUrl()
        guard let url = URL(string: baseUrl + api) else {
            throw ApiError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.timeoutInterval = sendTimeout
        
        // Áp dụng default headers
        for (key, value) in defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Thêm headers vào request (ghi đè default headers nếu trùng)
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        if let parameters = parameters {
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ApiError.invalidResponse
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                let errorString = String(data: data, encoding: .utf8) ?? "Không thể đọc dữ liệu lỗi"
                print("❌ Lỗi từ server: Mã \(httpResponse.statusCode), Nội dung: \(errorString)")
                throw ApiError.serverError(httpResponse.statusCode, String(data: data, encoding: .utf8) ?? "")
            }
            
        } catch {
            throw ApiError.networkError(error)
        }
    }
    
    open func delete<T: Decodable>(
        api: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        isBaseResponse: Bool = true,
        sendTimeout: TimeInterval =  5.0,
        receiveTimeout: TimeInterval =  5.0
    ) async throws -> T {
        try requireBaseUrl()
        var urlComponents = URLComponents(string: baseUrl + api)
        
        if let parameters = parameters {
            urlComponents?.queryItems = parameters.map {
                URLQueryItem(name: $0.key, value: "\($0.value)")
            }
        }
        
        guard let url = urlComponents?.url else {
            throw ApiError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.timeoutInterval = sendTimeout
        
        // Áp dụng default headers
        for (key, value) in defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Áp dụng headers được truyền vào (ghi đè default headers nếu trùng)
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ApiError.invalidResponse
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                let errorString = String(data: data, encoding: .utf8) ?? "Không thể đọc dữ liệu lỗi"
                print("❌ Lỗi từ server: Mã \(httpResponse.statusCode), Nội dung: \(errorString)")
                throw ApiError.serverError(httpResponse.statusCode, String(data: data, encoding: .utf8) ?? "")
            }
            
            if T.self == Void.self {
                return () as! T
            }
            let decoder = JSONDecoder()
            if isBaseResponse {
                let baseResponse = try decoder.decode(BaseResponse<T>.self, from: data)
                if let responseData = baseResponse.data {
                    return responseData
                }
                throw ApiError.invalidResponse
            } else {
                return try decoder.decode(T.self, from: data)
            }
            
        } catch let error as DecodingError {
            print("❌ Lỗi giải mã dữ liệu: \(error)")
            throw ApiError.decodingError(error)
        } catch {
            throw ApiError.networkError(error)
        }
    }
    
    open func delete(
        api: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        isBaseResponse: Bool = true,
        sendTimeout: TimeInterval = 5.0,
        receiveTimeout: TimeInterval =  5.0
    ) async throws {
        try requireBaseUrl()
        var urlComponents = URLComponents(string: baseUrl + api)
        
        if let parameters = parameters {
            urlComponents?.queryItems = parameters.map {
                URLQueryItem(name: $0.key, value: "\($0.value)")
            }
        }
        
        guard let url = urlComponents?.url else {
            throw ApiError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.timeoutInterval = sendTimeout
        
        // Áp dụng default headers
        for (key, value) in defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Áp dụng headers được truyền vào (ghi đè default headers nếu trùng)
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ApiError.invalidResponse
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                let errorString = String(data: data, encoding: .utf8) ?? "Không thể đọc dữ liệu lỗi"
                print("❌ Lỗi từ server: Mã \(httpResponse.statusCode), Nội dung: \(errorString)")
                throw ApiError.serverError(httpResponse.statusCode, String(data: data, encoding: .utf8) ?? "")
            }
            
        } catch {
            throw ApiError.networkError(error)
        }
    }
    
    
    // MARK: - GET List API
    open func getList<T: Codable>(
        api: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        isBaseResponse: Bool = true,
        sendTimeout: TimeInterval =  5.0,
        receiveTimeout: TimeInterval =  5.0
    ) async throws -> BaseListResponse<T> {
        try requireBaseUrl()
        var urlComponents = URLComponents(string: baseUrl + api)
        
        if let parameters = parameters {
            urlComponents?.queryItems = parameters.map {
                URLQueryItem(name: $0.key, value: "\($0.value)")
            }
        }
        
        guard let url = urlComponents?.url else {
            throw ApiError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = sendTimeout
        
        // Áp dụng default headers
        for (key, value) in defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Áp dụng headers được truyền vào (ghi đè default headers nếu trùng)
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("✅ JSON LIST : \n\(jsonString)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ApiError.invalidResponse
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                let errorString = String(data: data, encoding: .utf8) ?? "Không thể đọc dữ liệu lỗi"
                print("❌ Lỗi từ server: Mã \(httpResponse.statusCode), Nội dung: \(errorString)")
                throw ApiError.serverError(httpResponse.statusCode, String(data: data, encoding: .utf8) ?? "")
            }
            
            let decoder = JSONDecoder()
            let baseResponse = try decoder.decode(BaseListResponse<T>.self, from: data)
            return baseResponse
        } catch {
            print("❌ Có lỗi xảy ra khi gọi api \(error)")
            throw ApiError.networkError(error)
        }
    }
}
