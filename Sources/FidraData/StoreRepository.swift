//
//  StoreRepository.swift
//  FidraCore
//
//  Created by hi on 24/2/25.
//

import Foundation
import CoreData
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

/// Provides access to the Fidra Store, allowing fetching and caching of categories and items.
///
/// This repository interacts with a remote API (`ApiServerService`) and uses local caching
/// mechanisms (`DataStorageRepository`, `UserDefaultsManager`) to optimize data retrieval.
/// It also provides a fallback mechanism using `StoreDefaultRepository` in case of network errors or empty cache.
open class StoreRepository {
    /// The shared singleton instance of `StoreRepository`.
    public static let shared = StoreRepository()
    
    private let apiService: ApiServiceProtocol
    private let dataStorageCategoryRepository: DataStorageRepository<CategoryStorageModel>
    private let dataStorageItemRepository: DataStorageRepository<ItemStorageModel>
    private let userDefaultsManager: CacheManagerProtocol
    private let storeDefaultRepository: StoreDefaultRepositoryProtocol
    
    /// Initializes a new instance of the repository.
    public init(
        apiService: ApiServiceProtocol? = nil,
        dataStorageCategoryRepository: DataStorageRepository<CategoryStorageModel>? = nil,
        dataStorageItemRepository: DataStorageRepository<ItemStorageModel>? = nil,
        userDefaultsManager: CacheManagerProtocol? = nil,
        storeDefaultRepository: StoreDefaultRepositoryProtocol? = nil
    ) {
        self.apiService = apiService ?? ApiServerService(baseUrl: "")
        self.dataStorageCategoryRepository = dataStorageCategoryRepository ?? DataStorageRepository<CategoryStorageModel>(entityType: CategoryEntity.self)
        self.dataStorageItemRepository = dataStorageItemRepository ?? DataStorageRepository<ItemStorageModel>(entityType: ItemEntity.self)
        self.userDefaultsManager = userDefaultsManager ?? UserDefaultsManager()
        self.storeDefaultRepository = storeDefaultRepository ?? StoreDefaultRepository()
    }
    
    /// Fetches categories based on a parent ID.
    ///
    /// This method attempts to retrieve categories from the local cache first (if `useCache` is true
    /// and the cache is valid according to the refresh interval defined in `FidraRemoteConfig`).
    /// If the cache is not used, invalid, or empty, it fetches the categories from the remote API.
    /// Fetched data is then stored in the DataStorage cache.
    /// If fetching from the API fails, it tries to return cached data (if any).
    /// As a final fallback, it attempts to load categories from the `StoreDefaultRepository`.
    ///
    /// - Note: Categories with `customFields["minAppVersion"]` set will be filtered based on the current app version
    ///   (`CFBundleShortVersionString`). If the app version is lower than `minAppVersion`, the category is excluded.
    ///   This ensures older app versions do not display content they cannot support.
    ///   Version comparison uses semantic versioning (e.g. "1.2.3"). Missing segments are treated as 0.
    ///
    /// - Parameters:
    ///   - parentId: The ID of the parent category for which to fetch subcategories.
    ///   - useCache: A boolean indicating whether to attempt loading from the cache first. Defaults to `true`.
    /// - Returns: An array of `CategoryStoreModel` objects filtered by `minAppVersion`.
    /// - Throws: An error if fetching from the API and the fallback repository both fail, and no cached data is available.
    open func getCategories(parentId: String, useCache: Bool = true, forceFetchDataRemote: Bool = false,
     timeRefreshDataRemote: Int = 5,  sendTimeout: TimeInterval =  5.0,
                            receiveTimeout: TimeInterval =  5.0, apiKey: String, isReview: Bool = false) async throws -> [CategoryStoreModel] {
        do {
            if useCache {
                let userDefaults = userDefaultsManager
                if !userDefaults.shouldRefreshData(for: parentId, refreshInterval: forceFetchDataRemote ? 0 : timeRefreshDataRemote) {
                    print("DEBUG 🧡: get categories from cache")
                    let cachedCategories = try await dataStorageCategoryRepository.get(filter: "parentId == %@", args: parentId)
                    if !cachedCategories.isEmpty {
                        return applyVersionFilters(cachedCategories.map { $0.toModel() })
                    }
                }
            }
            
            // Fetch from API
//            let parameters = ["parent_id": parentId]
//            let categories: [CategoryStoreModel] = try await apiService.get(
//                api: "/stores/api/v6.0/public/categories",
//                parameters: parameters,
//                 headers: ["X-API-KEY": apiKey],
//                sendTimeout: sendTimeout,
//                receiveTimeout: receiveTimeout
//            )
            let parameters = ["parent_id": parentId]
            let categories: [CategoryStoreModel] = try await getCategoryFromApi(
                parentId: parentId,
                isReview: isReview,
                sendTimeout: sendTimeout,
                receiveTimeout: receiveTimeout,
                apiKey: apiKey
            )
            print("DEBUG 🧡: get categories from remote - length: \(categories.count)")
            
            if useCache {
                userDefaultsManager.saveLastFetchTime(for: parentId)
                let categoryStorageItems = categories.map { CategoryStorageModel(from: $0) }
                print("DEBUG 🧡: save categories to storage - length: \(categoryStorageItems.count)")
                // Use atomic replaceAll to prevent race condition
                try await dataStorageCategoryRepository.replaceAll(
                    filter: "parentId == %@",
                    filterValue: parentId,
                    with: categoryStorageItems
                )
            }
            return applyVersionFilters(categories)
        } catch {
            print("DEBUG 🧡: Error fetching categories - \(error)")
            if useCache {
                let cachedCategories = try? await dataStorageCategoryRepository.get(filter: "parentId == %@", args: parentId)
                if let cachedCategories = cachedCategories, !cachedCategories.isEmpty {
                    return applyVersionFilters(cachedCategories.map { $0.toModel() })
                }
            }
            // Fallback to default repository
            return applyVersionFilters(await storeDefaultRepository.getCategoriesWithCache(parentId: parentId, includeCustomField: true, isReview: isReview))
        }
    }
    
    /// Fetches items based on a category ID.
    ///
    /// Similar to `getCategories`, this method prioritizes fetching from the cache based on `useCache`
    /// and the configured refresh interval. If the cache is bypassed or invalid, it fetches items
    /// from the remote API via the `getItemsByCategory` helper method.
    /// Fetched items are stored in the DataStorage cache.
    /// If API fetching fails, it attempts to return cached data.
    /// The final fallback is retrieving items from `StoreDefaultRepository`.
    ///
    /// - Note: Items with `customFields["minAppVersion"]` set will be filtered based on the current app version
    ///   (`CFBundleShortVersionString`). If the app version is lower than `minAppVersion`, the item is excluded.
    ///   This ensures older app versions do not display content they cannot support.
    ///
    /// - Parameters:
    ///   - categoryId: The ID of the category for which to fetch items.
    ///   - useCache: A boolean indicating whether to use the cache. Defaults to `true`.
    /// - Returns: An array of `ItemStoreModel` objects filtered by `minAppVersion`.
    /// - Throws: An error if fetching from the API and the fallback repository both fail, and no cached data is available.
    open func getItems(categoryId: String, useCache: Bool = true, 
    forceFetchDataRemote: Bool = false, timeRefreshDataRemote: Int = 5,  sendTimeout: TimeInterval =  5.0,
                       receiveTimeout: TimeInterval =  5.0, apiKey: String, isReview: Bool = false) async throws -> [ItemStoreModel] {
        do {
            if useCache {
                let userDefaults = userDefaultsManager
                if !userDefaults.shouldRefreshData(for: categoryId, refreshInterval: forceFetchDataRemote ? 0 : timeRefreshDataRemote) {
                    print("DEBUG 🧡: get data categoryId = \(categoryId) from cache")
                    let cachedItems = try await dataStorageItemRepository.get(filter: "categoryId == %@", args: categoryId)
                    if !cachedItems.isEmpty {
                        return applyVersionFilters(cachedItems.map { $0.toModel() })
                    }
                }
            }
            
            let result = try await getItemsByCategory(categoryId: categoryId, isReview: isReview, sendTimeout: sendTimeout, receiveTimeout: receiveTimeout, apiKey: apiKey)
            print("DEBUG 🧡: get data categoryId = \(categoryId) from remote - length: \(result.count)")
            
            if useCache {
                userDefaultsManager.saveLastFetchTime(for: categoryId)
                let itemStorageObjects = result.map { ItemStorageModel(from: $0, categoryId: categoryId) }
                // Use atomic replaceAll to prevent race condition
                try await dataStorageItemRepository.replaceAll(
                    filter: "categoryId == %@",
                    filterValue: categoryId,
                    with: itemStorageObjects
                )
            }
            
            return applyVersionFilters(result)
        } catch {
            print("DEBUG 🧡: Error fetching items - \(error)")
            if useCache {
                let cachedItems = try? await dataStorageItemRepository.get(filter: "categoryId == %@", args: categoryId)
                if let cachedItems = cachedItems, !cachedItems.isEmpty {
                    return applyVersionFilters(cachedItems.map { $0.toModel() })
                }
            }
            // Fallback to default repository
            return applyVersionFilters(await storeDefaultRepository.getItemsWithCache(categoryId: categoryId, isReview: isReview))
        }
    }
    
    /// Fetches items with paging support based on a category ID.
    ///
    /// This method provides paging functionality while maintaining the same caching behavior
    /// as the regular `getItems` method. It attempts to retrieve items from the local cache first
    /// (if `useCache` is true and the cache is valid). If the cache is not used, invalid, or empty,
    /// it fetches items from the remote API with paging support.
    /// Fetched data is then stored in the DataStorage cache.
    /// If fetching from the API fails, it tries to return cached data (if any).
    /// As a final fallback, it attempts to load items from the `StoreDefaultRepository`.
    ///
    /// - Note: Items with `customFields["minAppVersion"]` set will be filtered based on the current app version
    ///   (`CFBundleShortVersionString`). If the app version is lower than `minAppVersion`, the item is excluded.
    ///   This may cause the returned count to be less than the requested `size`.
    ///
    /// - Parameters:
    ///   - categoryId: The ID of the category for which to fetch items.
    ///   - page: The page number to fetch (starting from 1).
    ///   - size: The number of items per page.
    ///   - useCache: A boolean indicating whether to use the cache. Defaults to `true`.
    ///   - forceFetchDataRemote: Whether to force fetch from remote API.
    ///   - timeRefreshDataRemote: Time interval in minutes for cache refresh.
    ///   - sendTimeout: Timeout for sending the request.
    ///   - receiveTimeout: Timeout for receiving the response.
    ///   - apiKey: The API key for authentication.
    /// - Returns: An array of `ItemStoreModel` objects for the specified page, filtered by `minAppVersion`.
    /// - Throws: An error if fetching from the API and the fallback repository both fail, and no cached data is available.
    open func getItemsWithPaging(categoryId: String, page: Int, size: Int, useCache: Bool = true, 
        forceFetchDataRemote: Bool = false, timeRefreshDataRemote: Int = 5, sendTimeout: TimeInterval = 5.0,
                                 receiveTimeout: TimeInterval = 5.0, apiKey: String, isReview: Bool = false) async throws -> [ItemStoreModel] {
        do {
            // Create unique cache key for paging to avoid conflicts with getItems
            // Format: "paging_{categoryId}_{page}_{size}"
            let pagingCacheKey = "paging_\(categoryId)_\(page)_\(size)"
            
            if useCache {
                let userDefaults = userDefaultsManager
                if !userDefaults.shouldRefreshData(for: pagingCacheKey, refreshInterval: forceFetchDataRemote ? 0 : timeRefreshDataRemote) {
                    print("DEBUG 🧡: get paging data categoryId = \(categoryId), page = \(page), size = \(size) from cache")
                    // Look for cached paging data with specific key
                    let cachedItems = try await dataStorageItemRepository.get(filter: "categoryId == %@", args: pagingCacheKey)
                    if !cachedItems.isEmpty {
                        return applyVersionFilters(cachedItems.map { $0.toModel() })
                    }
                }
            }
            
            let result = try await getItemsByCategoryWithPaging(
                categoryId: categoryId, 
                page: page, 
                size: size,
                isReview: isReview,
                sendTimeout: sendTimeout,
                receiveTimeout: receiveTimeout, 
                apiKey: apiKey
            )
            print("DEBUG 🧡: get paging data categoryId = \(categoryId), page = \(page), size = \(size) from remote - length: \(result.count)")
            
            if useCache {
                userDefaultsManager.saveLastFetchTime(for: pagingCacheKey)
                let itemStorageObjects = result.map { ItemStorageModel(from: $0, categoryId: pagingCacheKey) }
                print("DEBUG 🧡: save paging data to storage - key: \(pagingCacheKey), length: \(itemStorageObjects.count)")
                // Use atomic replaceAll to prevent race condition
                try await dataStorageItemRepository.replaceAll(
                    filter: "categoryId == %@",
                    filterValue: pagingCacheKey,
                    with: itemStorageObjects
                )
            }
            
            return applyVersionFilters(result)
        } catch {
            print("DEBUG 🧡: Error fetching items with paging - \(error)")
            if useCache {
                let pagingCacheKey = "paging_\(categoryId)_\(page)_\(size)"
                let cachedItems = try? await dataStorageItemRepository.get(filter: "categoryId == %@", args: pagingCacheKey)
                if let cachedItems = cachedItems, !cachedItems.isEmpty {
                    return applyVersionFilters(cachedItems.map { $0.toModel() })
                }
            }
            // Fallback to default repository (note: default repository doesn't support paging)
            let allItems = applyVersionFilters(await storeDefaultRepository.getItemsWithCache(categoryId: categoryId, isReview: isReview))
            let startIndex = (page - 1) * size
            let endIndex = min(startIndex + size, allItems.count)
            if startIndex < allItems.count {
                return Array(allItems[startIndex..<endIndex])
            }
            return []
        }
    }
    
    /// Fetches items directly from the API for a specific category.
    ///
    /// This is a helper method used by `getItems`. It also filters items based on the `isReview` flag
    /// from `FidraRemoteConfig` if necessary.
    ///
    /// - Parameter categoryId: The ID of the category.
    /// - Returns: An array of `ItemStoreModel` objects fetched from the API.
    /// - Throws: An error forwarded from the `apiService` if the network request fails.
    private func getItemsByCategory(categoryId: String, isReview: Bool = false, sendTimeout: TimeInterval =  5.0,
        receiveTimeout: TimeInterval =  5.0, apiKey: String) async throws -> [ItemStoreModel] {
        let parameters = ["category_id": categoryId]
        do {
            let items: [ItemStoreModel] = try await apiService.get(
                api: "/stores/api/v6.0/public/items/get-all", 
                parameters: parameters,
                headers: ["X-API-KEY": apiKey],
                sendTimeout: sendTimeout,
                receiveTimeout: receiveTimeout
            )
            if !isReview {
                return items
            }
            return items.filter { $0.customFields?["isNotForReview"] != "true" }
        } catch {
            throw error
        }
    }
    

    
    /// Fetches categories directly from the API for a specific parent ID.
    ///
    /// This helper method fetches categories from the remote API.
    /// It also filters categories based on the `isReview` flag from `FidraRemoteConfig` if necessary.
    ///
    /// - Parameter parentId: The ID of the parent category.
    /// - Returns: An array of `CategoryStoreModel` objects fetched from the API.
    /// - Throws: An error forwarded from the `apiService` if the network request fails.
    private func getCategoryFromApi(parentId: String, isReview: Bool = false, sendTimeout: TimeInterval =  5.0,
        receiveTimeout: TimeInterval =  5.0, apiKey: String) async throws -> [CategoryStoreModel] {
        let parameters = ["parent_id": parentId]
        do {
            let categories: [CategoryStoreModel] = try await apiService.get(
                api: "/stores/api/v6.0/public/categories",
                parameters: parameters,
                headers: ["X-API-KEY": apiKey],
                sendTimeout: sendTimeout,
                receiveTimeout: receiveTimeout
            )
            print("DEBUG 🧡: get categories from remote - length: \(categories.count)")
            if !isReview {
                return categories
            }
            return categories.filter { $0.customFields?["isNotForReview"] != "true" }
        } catch {
            throw error
        }
    }

    /// Fetches items by category with paging support from the API.
    ///
    /// This method fetches items from the remote API with pagination support.
    /// It allows you to specify page number and page size for efficient data loading.
    ///
    /// - Parameters:
    ///   - categoryId: The ID of the category for which to fetch items.
    ///   - page: The page number to fetch (starting from 1).
    ///   - size: The number of items per page.
    ///   - isReview: Whether to filter out items marked as not for review.
    ///   - sendTimeout: Timeout for sending the request.
    ///   - receiveTimeout: Timeout for receiving the response.
    ///   - apiKey: The API key for authentication.
    /// - Returns: An array of `ItemStoreModel` objects for the specified page.
    /// - Throws: An error if the network request fails.
    private func getItemsByCategoryWithPaging(categoryId: String, page: Int, size: Int, isReview: Bool = false, sendTimeout: TimeInterval = 5.0,
        receiveTimeout: TimeInterval = 5.0, apiKey: String) async throws -> [ItemStoreModel] {
        let parameters = [
            "category_id": categoryId,
            "page": String(page),
            "size": String(size)
        ]
        do {
            let items: [ItemStoreModel] = try await apiService.get(
                api: "/stores/api/v6.0/public/items/get-all", 
                parameters: parameters,
                headers: ["X-API-KEY": apiKey],
                sendTimeout: sendTimeout,
                receiveTimeout: receiveTimeout
            )
            print("DEBUG 🧡: get items with paging - categoryId: \(categoryId), page: \(page), size: \(size), count: \(items.count)")
            
            if !isReview {
                return items
            }
            return items.filter { $0.customFields?["isNotForReview"] != "true" }
        } catch {
            print("DEBUG 🧡: Error fetching items with paging - \(error)")
            throw error
        }
    }
    
    /// Compares two semantic version strings using dot-separated numeric components (e.g. "1.2.3").
    ///
    /// Missing segments are treated as 0 (e.g. "1.2" is equivalent to "1.2.0").
    /// Non-numeric segments are ignored during comparison.
    ///
    /// - Parameters:
    ///   - version: The current app version to check.
    ///   - minVersion: The minimum required version from `customFields["minAppVersion"]`.
    /// - Returns: `true` if `version` >= `minVersion`, or if `minVersion` is nil/empty.
    ///   Returns `false` if `version` is nil/empty but `minVersion` is set.
    private func isVersionSupported(_ version: String?, minVersion: String?) -> Bool {
        guard let minVersion = minVersion, !minVersion.isEmpty else { return true }
        guard let version = version, !version.isEmpty else { return false }
        let v1 = version.split(separator: ".").compactMap { Int($0) }
        let v2 = minVersion.split(separator: ".").compactMap { Int($0) }
        let maxCount = max(v1.count, v2.count)
        for i in 0..<maxCount {
            let a = i < v1.count ? v1[i] : 0
            let b = i < v2.count ? v2[i] : 0
            if a != b { return a > b }
        }
        return true
    }

    private var currentAppVersion: String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    private var currentIOSVersion: String {
        #if os(iOS) || os(tvOS)
        return UIDevice.current.systemVersion
        #elseif os(watchOS)
        return WKInterfaceDevice.current().systemVersion
        #elseif os(macOS)
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        #else
        return ""
        #endif
    }

    private func filterByMinAppVersion<T>(_ items: [T], appVersion: String? = nil) -> [T] where T: MinAppVersionFilterable {
        let version = appVersion ?? currentAppVersion
        guard let version = version, !version.isEmpty else { return items }
        return items.filter { isVersionSupported(version, minVersion: $0.minAppVersion) }
    }

    private func filterByMinIOSVersion<T>(_ items: [T], iosVersion: String? = nil) -> [T] where T: MinAppVersionFilterable {
        let version = iosVersion ?? currentIOSVersion
        guard !version.isEmpty else { return items }
        return items.filter { isVersionSupported(version, minVersion: $0.minIOSVersion) }
    }

    private func applyVersionFilters<T>(_ items: [T]) -> [T] where T: MinAppVersionFilterable {
        return filterByMinIOSVersion(filterByMinAppVersion(items))
    }

    /// Clears all cached data managed by this repository.
    ///
    /// This includes deleting all category and item objects from their respective DataStorage repositories
    /// and clearing all recorded fetch times from `UserDefaultsManager`.
    open func clearCache() async throws {
        try await dataStorageCategoryRepository.deleteAll()
        try await dataStorageItemRepository.deleteAll()
        userDefaultsManager.clearAllFetchTimes()
    }
}
