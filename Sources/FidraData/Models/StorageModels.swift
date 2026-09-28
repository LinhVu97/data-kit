import Foundation
import DataStorageKit

public struct ItemStorageModel: DomainModel {
    public var id: String
    public var createdAt: Date
    public var updatedAt: Date
    
    public var categoryId: String
    public var name: String
    public var thumbnail: String?
    public var photo: String?
    public var priority: Int
    public var status: Bool
    public var isNew: Bool
    public var isPro: Bool
    public var oldId: Int
    public var children: String?
    public var customFields: [String: String]?
    
    public init(from model: ItemStoreModel, categoryId: String) {
        self.id = model.id
        self.categoryId = categoryId
        self.name = model.name
        self.thumbnail = model.thumbnail
        self.photo = model.photo
        self.priority = model.priority
        self.status = model.status
        self.isNew = model.isNew
        self.isPro = model.isPro
        self.oldId = model.oldId
        
        if let children = model.children {
            do {
                let jsonData = try JSONEncoder().encode(children)
                self.children = String(data: jsonData, encoding: .utf8)
            } catch {
                self.children = nil
            }
        } else {
            self.children = nil
        }
        
        self.customFields = model.customFields
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    public init(from entity: ItemEntity) {
        self.id = entity.id ?? ""
        self.createdAt = entity.createdAt ?? Date()
        self.updatedAt = entity.updatedAt ?? Date()
        self.categoryId = entity.categoryId ?? ""
        self.name = entity.name ?? ""
        self.thumbnail = entity.thumbnail
        self.photo = entity.photo
        self.priority = Int(entity.priority)
        self.status = entity.status
        self.isNew = entity.isNew
        self.isPro = entity.isPro
        self.oldId = Int(entity.oldId)
        self.children = entity.children
        if let data = entity.customFields {
            self.customFields = try? JSONDecoder().decode([String: String].self, from: data)
        } else {
            self.customFields = nil
        }
    }
    
    public init(
        id: String,
        createdAt: Date,
        updatedAt: Date,
        categoryId: String,
        name: String,
        thumbnail: String?,
        photo: String?,
        priority: Int,
        status: Bool,
        isNew: Bool,
        isPro: Bool,
        oldId: Int,
        children: String?,
        customFields: [String: String]?
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.categoryId = categoryId
        self.name = name
        self.thumbnail = thumbnail
        self.photo = photo
        self.priority = priority
        self.status = status
        self.isNew = isNew
        self.isPro = isPro
        self.oldId = oldId
        self.children = children
        self.customFields = customFields
    }
    
    public func toModel() -> ItemStoreModel {
        var childrenArray: [ItemStoreModel]?
        if let childrenJson = children {
            do {
                let jsonData = childrenJson.data(using: .utf8)
                if let data = jsonData {
                    childrenArray = try JSONDecoder().decode([ItemStoreModel].self, from: data)
                }
            } catch {
                childrenArray = nil
            }
        }
        
        return ItemStoreModel(
            id: id,
            categoryId: categoryId,
            name: name,
            thumbnail: thumbnail,
            photo: photo,
            priority: priority,
            status: status,
            isNew: isNew,
            isPro: isPro,
            oldId: oldId,
            children: childrenArray,
            customFields: customFields
        )
    }
}

public struct CategoryStorageModel: DomainModel {
    public var id: String
    public var createdAt: Date
    public var updatedAt: Date
    
    public var parentId: String?
    public var priority: Int
    public var name: String
    public var status: Bool
    public var thumbnail: String?
    public var photo: String?
    public var isNew: Bool
    public var isPro: Bool
    public var oldId: Int
    public var customFields: [String: String]?
    
    public init(from model: CategoryStoreModel) {
        self.id = model.id
        self.parentId = model.parentId
        self.priority = model.priority
        self.name = model.name
        self.status = model.status
        self.thumbnail = model.thumbnail
        self.photo = model.photo
        self.isNew = model.isNew
        self.isPro = model.isPro
        self.oldId = model.oldId
        self.customFields = model.customFields
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    public init(from entity: CategoryEntity) {
        self.id = entity.id ?? ""
        self.createdAt = entity.createdAt ?? Date()
        self.updatedAt = entity.updatedAt ?? Date()
        self.parentId = entity.parentId
        self.priority = Int(entity.priority)
        self.name = entity.name ?? ""
        self.status = entity.status
        self.thumbnail = entity.thumbnail
        self.photo = entity.photo
        self.isNew = entity.isNew
        self.isPro = entity.isPro
        self.oldId = Int(entity.oldId)
        if let data = entity.customFields {
            self.customFields = try? JSONDecoder().decode([String: String].self, from: data)
        } else {
            self.customFields = nil
        }
    }
    
    public init(
        id: String,
        createdAt: Date,
        updatedAt: Date,
        parentId: String?,
        priority: Int,
        name: String,
        status: Bool,
        thumbnail: String?,
        photo: String?,
        isNew: Bool,
        isPro: Bool,
        oldId: Int,
        customFields: [String: String]?
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.parentId = parentId
        self.priority = priority
        self.name = name
        self.status = status
        self.thumbnail = thumbnail
        self.photo = photo
        self.isNew = isNew
        self.isPro = isPro
        self.oldId = oldId
        self.customFields = customFields
    }
    
    public func toModel() -> CategoryStoreModel {
        return CategoryStoreModel(
            id: id,
            parentId: parentId,
            priority: priority,
            name: name,
            status: status,
            thumbnail: thumbnail,
            photo: photo,
            isNew: isNew,
            isPro: isPro,
            oldId: oldId,
            customFields: customFields
        )
    }
}

