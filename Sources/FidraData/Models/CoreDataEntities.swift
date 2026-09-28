import Foundation
import CoreData
import DataStorageKit

@objc(CategoryEntity)
public final class CategoryEntity: NSManagedObject, CoreDataMappable {
    public typealias Domain = CategoryStorageModel
    
    @nonobjc public class func fetchRequest(query: String?) -> NSFetchRequest<CategoryEntity> {
        let request = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        if let query = query {
            request.predicate = NSPredicate(format: query)
        }
        return request
    }
    
    @nonobjc public class func fetchRequest(id: String) -> NSFetchRequest<CategoryEntity> {
        let request = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        request.predicate = NSPredicate(format: "id == %@", id)
        return request
    }
    
    public static func from(domain: CategoryStorageModel, context: NSManagedObjectContext) -> CategoryEntity {
        let entity = CategoryEntity(context: context)
        entity.id = domain.id
        entity.createdAt = domain.createdAt
        entity.updatedAt = domain.updatedAt
        entity.parentId = domain.parentId
        entity.priority = Int32(domain.priority)
        entity.name = domain.name
        entity.status = domain.status
        entity.thumbnail = domain.thumbnail
        entity.photo = domain.photo
        entity.isNew = domain.isNew
        entity.isPro = domain.isPro
        entity.oldId = Int32(domain.oldId)
        if let customFields = domain.customFields {
            entity.customFields = try? JSONEncoder().encode(customFields)
        }
        return entity
    }
    
    public func toDomain() -> CategoryStorageModel {
        var result: CategoryStorageModel!
        
        if let context = self.managedObjectContext {
            context.performAndWait {
                result = CategoryStorageModel(from: self)
            }
        } else {
            // Fallback if no context (shouldn't happen in normal usage)
            result = CategoryStorageModel(from: self)
        }
        
        return result
    }
}

extension CategoryEntity {
    @NSManaged public var id: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var parentId: String?
    @NSManaged public var priority: Int32
    @NSManaged public var name: String?
    @NSManaged public var status: Bool
    @NSManaged public var thumbnail: String?
    @NSManaged public var photo: String?
    @NSManaged public var isNew: Bool
    @NSManaged public var isPro: Bool
    @NSManaged public var oldId: Int32
    @NSManaged public var customFields: Data?
}

@objc(ItemEntity)
public final class ItemEntity: NSManagedObject, CoreDataMappable {
    public typealias Domain = ItemStorageModel
    
    @nonobjc public class func fetchRequest(query: String?) -> NSFetchRequest<ItemEntity> {
        let request = NSFetchRequest<ItemEntity>(entityName: "ItemEntity")
        if let query = query {
            request.predicate = NSPredicate(format: query)
        }
        return request
    }
    
    @nonobjc public class func fetchRequest(id: String) -> NSFetchRequest<ItemEntity> {
        let request = NSFetchRequest<ItemEntity>(entityName: "ItemEntity")
        request.predicate = NSPredicate(format: "id == %@", id)
        return request
    }
    
    public static func from(domain: ItemStorageModel, context: NSManagedObjectContext) -> ItemEntity {
        let entity = ItemEntity(context: context)
        entity.id = domain.id
        entity.createdAt = domain.createdAt
        entity.updatedAt = domain.updatedAt
        entity.categoryId = domain.categoryId
        entity.name = domain.name
        entity.thumbnail = domain.thumbnail
        entity.photo = domain.photo
        entity.priority = Int32(domain.priority)
        entity.status = domain.status
        entity.isNew = domain.isNew
        entity.isPro = domain.isPro
        entity.oldId = Int32(domain.oldId)
        entity.children = domain.children
        if let customFields = domain.customFields {
            entity.customFields = try? JSONEncoder().encode(customFields)
        }
        return entity
    }
    
    public func toDomain() -> ItemStorageModel {
        var result: ItemStorageModel!
        
        if let context = self.managedObjectContext {
            context.performAndWait {
                result = ItemStorageModel(from: self)
            }
        } else {
            // Fallback if no context (shouldn't happen in normal usage)
            result = ItemStorageModel(from: self)
        }
        
        return result
    }
}

extension ItemEntity {
    @NSManaged public var id: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var categoryId: String?
    @NSManaged public var name: String?
    @NSManaged public var thumbnail: String?
    @NSManaged public var photo: String?
    @NSManaged public var priority: Int32
    @NSManaged public var status: Bool
    @NSManaged public var isNew: Bool
    @NSManaged public var isPro: Bool
    @NSManaged public var oldId: Int32
    @NSManaged public var children: String?
    @NSManaged public var customFields: Data?
}

