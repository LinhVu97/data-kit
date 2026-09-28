import Foundation

public protocol ApiServiceProtocol {
    func get<T: Decodable>(
        api: String,
        parameters: [String: Any]?,
        headers: [String: String]?,
        isBaseResponse: Bool,
        sendTimeout: TimeInterval,
        receiveTimeout: TimeInterval
    ) async throws -> T
    
    func post<T: Decodable>(
        api: String,
        parameters: [String: Any]?,
        headers: [String: String]?,
        isBaseResponse: Bool,
        sendTimeout: TimeInterval,
        receiveTimeout: TimeInterval
    ) async throws -> T
    
    func post(
        api: String,
        parameters: [String: Any]?,
        headers: [String: String]?,
        isBaseResponse: Bool,
        sendTimeout: TimeInterval,
        receiveTimeout: TimeInterval
    ) async throws
    
    func put<T: Decodable>(
        api: String,
        parameters: [String: Any]?,
        headers: [String: String]?,
        isBaseResponse: Bool,
        sendTimeout: TimeInterval,
        receiveTimeout: TimeInterval
    ) async throws -> T
    
    func put(
        api: String,
        parameters: [String: Any]?,
        headers: [String: String]?,
        isBaseResponse: Bool,
        sendTimeout: TimeInterval,
        receiveTimeout: TimeInterval
    ) async throws
    
    func delete<T: Decodable>(
        api: String,
        parameters: [String: Any]?,
        headers: [String: String]?,
        isBaseResponse: Bool,
        sendTimeout: TimeInterval,
        receiveTimeout: TimeInterval
    ) async throws -> T
    
    func delete(
        api: String,
        parameters: [String: Any]?,
        headers: [String: String]?,
        isBaseResponse: Bool,
        sendTimeout: TimeInterval,
        receiveTimeout: TimeInterval
    ) async throws
    
    func getList<T: Codable>(
        api: String,
        parameters: [String: Any]?,
        headers: [String: String]?,
        isBaseResponse: Bool,
        sendTimeout: TimeInterval,
        receiveTimeout: TimeInterval
    ) async throws -> BaseListResponse<T>
    
    func addDefaultHeader(key: String, value: String)
    func setDefaultHeaders(_ headers: [String: String])
}
