import Foundation
import CoreData
import DataStorageKit

public final class FidraPersistenceController {
    public static let shared = FidraPersistenceController()
    public let container: NSPersistentContainer
    
    public init(inMemory: Bool = false) {
        let bundle = Bundle.module
        guard let modelURL = bundle.url(forResource: "DataStorageModel", withExtension: "momd") else {
            fatalError("Failed to find DataStorageModel.momd in bundle \(bundle.bundleURL)")
        }
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to load model from \(modelURL)")
        }
        
        container = NSPersistentContainer(name: "DataStorageModel", managedObjectModel: model)
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            let storeDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            let storeURL = storeDirectory?.appendingPathComponent("FidraData.sqlite")
            if let directory = storeDirectory {
                try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            if let storeURL {
                container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: storeURL)]
            }
        }
        
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unresolved Core Data error: \(error)")
            }
        }
        
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

