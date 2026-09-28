import Foundation
import RealmSwift

public class RealmRepository<T: Object> {
    
    private var realm: Realm?
    
    public init() {
        // Initialize realm lazily when needed
        setupRealm()
    }
    
    private func setupRealm() {
        let config = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: nil,
            deleteRealmIfMigrationNeeded: true
        )
        
        Realm.Configuration.defaultConfiguration = config
    }
    
    private func getRealm() -> Realm {
        do {
            // Get a new instance for the current thread
            return try Realm()
        } catch {
            fatalError("Failed to initialize Realm: \(error)")
        }
    }
    
    // MARK: - Generic CRUD Operations
    public func getAll() -> [T] {
        let realm = getRealm()
        let objects = realm.objects(T.self)
        // Thêm .freeze() để tránh lỗi đối tượng bị xóa hoặc vô hiệu hóa
        return Array(objects.freeze())
    }
    
    public func get(filter: String, args: Any...) -> [T] {
        let realm = getRealm()
        let objects = realm.objects(T.self).filter(filter, args)
        // Thêm .freeze() để tránh lỗi đối tượng bị xóa hoặc vô hiệu hóa
        return Array(objects.freeze())
    }
    
    public func save(_ items: [T]) {
        let realm = getRealm()
        try? realm.write {
            realm.add(items, update: .modified)
        }
    }
    
    public func updateById(id: String, updateBlock: (T) -> Void) {
        let realm = getRealm()
        do {
            try realm.write {
                if let object = realm.object(ofType: T.self, forPrimaryKey: id) {
                    updateBlock(object)
                } else {
                    print("Object with id: \(id) not found")
                }
            }
        } catch {
            print("Error updating object: \(error)")
        }
    }
    
    public func delete(filter: String, args: Any...)  {
        let realm = getRealm()
        do {
            try realm.write {
                let objectsToDelete = realm.objects(T.self).filter(filter, args)
                realm.delete(objectsToDelete)
            }
        } catch {
            print("Lỗi khi xoá: \(error)")
        }
    }
    
    public func deleteAll() {
        let realm = getRealm()
        try? realm.write {
            let objects = realm.objects(T.self)
            realm.delete(objects)
        }
    }
    
    
    // MARK: - Cache Management
    func clearCache() {
        let realm = getRealm()
        try? realm.write {
            realm.deleteAll()
        }
    }
}
