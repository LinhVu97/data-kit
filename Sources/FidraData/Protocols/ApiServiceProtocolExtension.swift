import Foundation

public extension ApiServiceProtocol {
    func get<T: Decodable>(
        api: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        isBaseResponse: Bool = true,
        sendTimeout: TimeInterval = 5.0,
        receiveTimeout: TimeInterval = 5.0
    ) async throws -> T {
        return try await get(
            api: api,
            parameters: parameters,
            headers: headers,
            isBaseResponse: isBaseResponse,
            sendTimeout: sendTimeout,
            receiveTimeout: receiveTimeout
        )
    }
    
    func post<T: Decodable>(
        api: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        isBaseResponse: Bool = true,
        sendTimeout: TimeInterval = 5.0,
        receiveTimeout: TimeInterval = 5.0
    ) async throws -> T {
        return try await post(
            api: api,
            parameters: parameters,
            headers: headers,
            isBaseResponse: isBaseResponse,
            sendTimeout: sendTimeout,
            receiveTimeout: receiveTimeout
        )
    }
    
    func post(
        api: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        isBaseResponse: Bool = true,
        sendTimeout: TimeInterval = 5.0,
        receiveTimeout: TimeInterval = 5.0
    ) async throws {
        try await post(
            api: api,
            parameters: parameters,
            headers: headers,
            isBaseResponse: isBaseResponse,
            sendTimeout: sendTimeout,
            receiveTimeout: receiveTimeout
        )
    }
    
    func put<T: Decodable>(
        api: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        isBaseResponse: Bool = true,
        sendTimeout: TimeInterval = 5.0,
        receiveTimeout: TimeInterval = 5.0
    ) async throws -> T {
        return try await put(
            api: api,
            parameters: parameters,
            headers: headers,
            isBaseResponse: isBaseResponse,
            sendTimeout: sendTimeout,
            receiveTimeout: receiveTimeout
        )
    }
    
    func put(
        api: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        isBaseResponse: Bool = true,
        sendTimeout: TimeInterval = 5.0,
        receiveTimeout: TimeInterval = 5.0
    ) async throws {
        try await put(
            api: api,
            parameters: parameters,
            headers: headers,
            isBaseResponse: isBaseResponse,
            sendTimeout: sendTimeout,
            receiveTimeout: receiveTimeout
        )
    }
    
    func delete<T: Decodable>(
        api: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        isBaseResponse: Bool = true,
        sendTimeout: TimeInterval = 5.0,
        receiveTimeout: TimeInterval = 5.0
    ) async throws -> T {
        return try await delete(
            api: api,
            parameters: parameters,
            headers: headers,
            isBaseResponse: isBaseResponse,
            sendTimeout: sendTimeout,
            receiveTimeout: receiveTimeout
        )
    }
    
    func delete(
        api: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        isBaseResponse: Bool = true,
        sendTimeout: TimeInterval = 5.0,
        receiveTimeout: TimeInterval = 5.0
    ) async throws {
        try await delete(
            api: api,
            parameters: parameters,
            headers: headers,
            isBaseResponse: isBaseResponse,
            sendTimeout: sendTimeout,
            receiveTimeout: receiveTimeout
        )
    }
    
    func getList<T: Codable>(
        api: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        isBaseResponse: Bool = true,
        sendTimeout: TimeInterval = 5.0,
        receiveTimeout: TimeInterval = 5.0
    ) async throws -> BaseListResponse<T> {
        return try await getList(
            api: api,
            parameters: parameters,
            headers: headers,
            isBaseResponse: isBaseResponse,
            sendTimeout: sendTimeout,
            receiveTimeout: receiveTimeout
        )
    }
}
