import Foundation
import CoreData
import DataStorageKit

public class DataStorageRepository<T: DomainModel>: DataStorageRepositoryProtocol {
    public typealias Model = T
    
    private let storage: any AsyncStorage<T>
    
    public init<Entity: CoreDataMappable>(
        entityType: Entity.Type,
        context: NSManagedObjectContext = FidraPersistenceController.shared.container.viewContext
    ) where Entity.Domain == T {
        self.storage = DataStorageKit.coreData(entityType: entityType, context: context)
    }
    
    public convenience init(inMemory: Bool = true) {
        self.init(storage: DataStorageKit.inMemory())
    }
    
    private init(storage: any AsyncStorage<T>) {
        self.storage = storage
    }
    
    public func getAll() async throws -> [T] {
        return try await storage.getAll()
    }
    
    public func get(filter: String, args: Any...) async throws -> [T] {
        let allItems = try await storage.getAll()
        
        if filter.isEmpty {
            return allItems
        }
        
        // Simple predicate matching
        if filter == "parentId == %@" {
            guard let parentId = args.first as? String else { return [] }
            return allItems.filter { ($0 as? CategoryStorageModel)?.parentId == parentId }
        }
        
        if filter == "categoryId == %@" {
            guard let categoryId = args.first as? String else { return [] }
            return allItems.filter { ($0 as? ItemStorageModel)?.categoryId == categoryId }
        }
        
        return allItems
    }
    
    public func save(_ items: [T]) async throws {
        for item in items {
            if let categoryModel = item as? CategoryStorageModel {
                let context = FidraPersistenceController.shared.container.viewContext
                await context.perform {
                    let entity = CategoryEntity.from(domain: categoryModel, context: context)
                    try? context.save()
                }
            } else if let itemModel = item as? ItemStorageModel {
                let context = FidraPersistenceController.shared.container.viewContext
                await context.perform {
                    let entity = ItemEntity.from(domain: itemModel, context: context)
                    try? context.save()
                }
            }
        }
    }
    
    public func updateById(id: String, updateBlock: (inout T) -> Void) async throws {
        guard var object = try await storage.get(id: id) else {
            print("Object with id: \(id) not found")
            return
        }
        
        updateBlock(&object)
        
        try await storage.update(id: id, object)
    }
    
    public func delete(filter: String, args: Any...) async throws {
        let itemsToDelete = try await get(filter: filter, args: args)
        for item in itemsToDelete {
            try await storage.delete(id: item.id)
        }
    }
    
    public func deleteAll() async throws {
        try await storage.deleteAll()
    }
    
    public func clearCache() async throws {
        try await deleteAll()
    }
    
    /// Atomically replaces all items matching the filter with new items.
    /// This prevents race conditions when multiple threads try to update the same data.
    public func replaceAll(filter: String, filterValue: String, with newItems: [T]) async throws {
        let context = FidraPersistenceController.shared.container.viewContext
        
        try await context.perform {
            // Step 1: Delete existing items matching filter
            if filter == "parentId == %@" {
                let fetchRequest = CategoryEntity.fetchRequest(query: "parentId == '\(filterValue)'")
                let existingItems = try context.fetch(fetchRequest)
                for item in existingItems {
                    context.delete(item)
                }
                
                // Step 2: Create new entities
                for item in newItems {
                    if let categoryModel = item as? CategoryStorageModel {
                        _ = CategoryEntity.from(domain: categoryModel, context: context)
                    }
                }
            } else if filter == "categoryId == %@" {
                let fetchRequest = ItemEntity.fetchRequest(query: "categoryId == '\(filterValue)'")
                let existingItems = try context.fetch(fetchRequest)
                for item in existingItems {
                    context.delete(item)
                }
                
                // Step 2: Create new entities
                for item in newItems {
                    if let itemModel = item as? ItemStorageModel {
                        _ = ItemEntity.from(domain: itemModel, context: context)
                    }
                }
            }
            
            // Step 3: Save context (atomic operation)
            if context.hasChanges {
                try context.save()
            }
        }
    }
}

