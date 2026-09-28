import Foundation
import DataStorageKit

public protocol DataStorageRepositoryProtocol {
    associatedtype Model: DomainModel
    
    func getAll() async throws -> [Model]
    func get(filter: String, args: Any...) async throws -> [Model]
    func save(_ items: [Model]) async throws
    func updateById(id: String, updateBlock: (inout Model) -> Void) async throws
    func delete(filter: String, args: Any...) async throws
    func deleteAll() async throws
    func clearCache() async throws
    
    /// Atomically replaces all items matching the filter with new items.
    /// This operation is thread-safe and prevents race conditions when multiple
    /// threads try to update the same data simultaneously.
    /// - Parameters:
    ///   - filter: The filter predicate string (e.g., "parentId == %@")
    ///   - filterValue: The value to match in the filter
    ///   - newItems: The new items to save after deletion
    func replaceAll(filter: String, filterValue: String, with newItems: [Model]) async throws
}
