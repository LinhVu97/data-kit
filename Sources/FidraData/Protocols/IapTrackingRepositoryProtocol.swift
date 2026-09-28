import Foundation

public protocol IapTrackingRepositoryProtocol {
    func trackInitUser(params: [String: Any]) async throws
    
    func trackPurchaseFailure(params: [String: Any]) async throws
}

