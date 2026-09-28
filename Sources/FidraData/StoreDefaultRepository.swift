
//
//  StoreDefaultRepository.swift
//  FidraCore
//
//  Created by hi on 21/4/25.
//

import Foundation

public class StoreDefaultRepository: StoreDefaultRepositoryProtocol {
    private let appJsonPath = "app.json" // Đặt file app.json vào main bundle
    
    public init() {}
    
    // MARK: - Đọc dữ liệu từ file JSON
    private func readJsonFile() -> [[String: Any]]? {
        guard let url = Bundle.main.url(forResource: "app", withExtension: "json", subdirectory: "Json")
            ?? Bundle.main.url(forResource: "app", withExtension: "json") else {
            print("DEBUG 🧡: app.json not found in bundle")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let jsonObj = try JSONSerialization.jsonObject(with: data, options: [])
            return jsonObj as? [[String: Any]]
        } catch {
            print("DEBUG 🧡: Error reading JSON file: \(error)")
            return nil
        }
    }
    
    // MARK: - Lấy tất cả item theo categoryId từ file JSON local
    public func getAllItemByCategory(categoryId: String, regionCode: String? = nil, isReview: Bool = false) async -> [ItemStoreModel] {
        guard let appData = readJsonFile() else { return [] }
        var items: [ItemStoreModel] = []
        for category in appData {
            // Kiểm tra items trực tiếp trong category
            if let categoryItems = category["items"] as? [[String: Any]] {
                let filtered = categoryItems.filter { ($0["category_id"] as? String) == categoryId }
                items.append(contentsOf: filtered.compactMap { ItemStoreModel.from(json: $0) })
            }
            // Kiểm tra trong children của category
            if let children = category["children"] as? [[String: Any]] {
                findItemsInChildren(children: children, categoryId: categoryId, items: &items)
            }
        }
        if isReview {
            let itemsReview = items.filter { $0.customFields?["isNotForReview"] != "true" }
            return itemsReview
        }
        return items
    }
    
    // MARK: - Lấy tất cả item theo categoryId từ file JSON local (không sử dụng cache)
    public func getItemsWithCache(categoryId: String, isReview: Bool = false) async -> [ItemStoreModel] {
        let result = await getAllItemByCategory(categoryId: categoryId, isReview: isReview)
        print("DEBUG 🧡: get data categoryId = \(categoryId) from local JSON - length: \(result.count)")
        return result
    }
    
    // MARK: - Hàm đệ quy để tìm items trong children
    private func findItemsInChildren(children: [[String: Any]], categoryId: String, items: inout [ItemStoreModel]) {
        for child in children {
            if let childItems = child["items"] as? [[String: Any]] {
                let filtered = childItems.filter { ($0["category_id"] as? String) == categoryId }
                items.append(contentsOf: filtered.compactMap { ItemStoreModel.from(json: $0) })
            }
            if let subChildren = child["children"] as? [[String: Any]] {
                findItemsInChildren(children: subChildren, categoryId: categoryId, items: &items)
            }
        }
    }
    
    // MARK: - Helper method để xử lý children items trong ItemStoreModel
    public func processChildrenItems(_ items: [ItemStoreModel]) -> [ItemStoreModel] {
        var processedItems: [ItemStoreModel] = []
        
        for item in items {
            // Add the main item
            processedItems.append(item)
            
            // Recursively process children items
            if let children = item.children {
                let processedChildren = processChildrenItems(children)
                processedItems.append(contentsOf: processedChildren)
            }
        }
        
        return processedItems
    }
    
    // MARK: - Lấy tất cả category theo parentId từ file JSON local
    public func getAllCategoryByParent(parentId: String, includeCustomField: Bool = true, isReview: Bool = false) async -> [CategoryStoreModel] {
        guard let appData = readJsonFile() else { return [] }
        var categories: [CategoryStoreModel] = []
        for category in appData {
            if let catParentId = category["parent_id"] as? String,
               let catId = category["id"] as? String,
               catParentId == parentId,
               catParentId != catId {
                if let model = CategoryStoreModel.from(json: category) {
                    categories.append(model)
                }
            }
            if let children = category["children"] as? [[String: Any]] {
                findCategoriesInChildren(children: children, parentId: parentId, categories: &categories)
            }
        }
        if isReview {
            let categoriesReview = categories.filter { $0.customFields?["isNotForReview"] != "true" }
            return categoriesReview
        }
        return categories
    }
    
    // MARK: - Hàm đệ quy để tìm categories trong children
    private func findCategoriesInChildren(children: [[String: Any]], parentId: String, categories: inout [CategoryStoreModel]) {
        for child in children {
            if let catParentId = child["parent_id"] as? String, catParentId == parentId {
                if let model = CategoryStoreModel.from(json: child) {
                    categories.append(model)
                }
            }
            if let subChildren = child["children"] as? [[String: Any]] {
                findCategoriesInChildren(children: subChildren, parentId: parentId, categories: &categories)
            }
        }
    }
    
    // MARK: - Lấy tất cả category theo parentId từ file JSON local (không sử dụng cache)
    public func getCategoriesWithCache(parentId: String, includeCustomField: Bool = true, isReview: Bool = false) async -> [CategoryStoreModel] {
        let result = await getAllCategoryByParent(parentId: parentId, includeCustomField: includeCustomField, isReview: isReview)
        print("DEBUG 🧡: get data parentId = \(parentId) from local JSON - length: \(result.count)")
        return result
    }
}
