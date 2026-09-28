import Foundation

public protocol StoreDefaultRepositoryProtocol {
    func getCategoriesWithCache(parentId: String, includeCustomField: Bool, isReview: Bool) async -> [CategoryStoreModel]
    func getItemsWithCache(categoryId: String, isReview: Bool) async -> [ItemStoreModel]
    func processChildrenItems(_ items: [ItemStoreModel]) -> [ItemStoreModel]
}
