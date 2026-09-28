import XCTest
@testable import FidraData

final class FidraDataTests: XCTestCase {
    
    func testItemStoreModelWithChildren() throws {
        // Test creating ItemStoreModel with children
        let childItem = ItemStoreModel(
            id: "child1",
            categoryId: "cat2",
            name: "Child Item",
            thumbnail: nil,
            photo: nil,
            priority: 1,
            status: true,
            isNew: false,
            isPro: false,
            oldId: 0,
            children: nil,
            customFields: nil
        )
        
        let parentItem = ItemStoreModel(
            id: "parent1",
            categoryId: "cat1",
            name: "Parent Item",
            thumbnail: "thumb1",
            photo: "photo1",
            priority: 0,
            status: true,
            isNew: true,
            isPro: true,
            oldId: 0,
            children: [childItem],
            customFields: ["key1": "value1"]
        )
        
        // Test basic properties
        XCTAssertEqual(parentItem.id, "parent1")
        XCTAssertEqual(parentItem.name, "Parent Item")
        XCTAssertTrue(parentItem.hasChildren)
        XCTAssertEqual(parentItem.children?.count, 1)
        XCTAssertEqual(parentItem.totalItemCount, 2)
        
        // Test children properties
        XCTAssertEqual(parentItem.children?.first?.id, "child1")
        XCTAssertEqual(parentItem.children?.first?.name, "Child Item")
        XCTAssertFalse(parentItem.children?.first?.hasChildren ?? true)
        
        // Test allChildren method
        let allChildren = parentItem.allChildren
        XCTAssertEqual(allChildren.count, 1)
        XCTAssertEqual(allChildren.first?.id, "child1")
    }
    
    func testItemStoreModelWithoutChildren() throws {
        let item = ItemStoreModel(
            id: "item1",
            categoryId: "cat1",
            name: "Single Item",
            thumbnail: nil,
            photo: nil,
            priority: 0,
            status: true,
            isNew: false,
            isPro: false,
            oldId: 0,
            children: nil,
            customFields: nil
        )
        
        XCTAssertFalse(item.hasChildren)
        XCTAssertEqual(item.allChildren.count, 0)
        XCTAssertEqual(item.totalItemCount, 1)
        XCTAssertNil(item.children)
    }
    
    func testFindChildMethod() throws {
        let grandChild = ItemStoreModel(
            id: "grandchild1",
            categoryId: "cat3",
            name: "Grandchild Item",
            thumbnail: nil,
            photo: nil,
            priority: 0,
            status: true,
            isNew: false,
            isPro: false,
            oldId: 0,
            children: nil,
            customFields: nil
        )
        
        let child = ItemStoreModel(
            id: "child1",
            categoryId: "cat2",
            name: "Child Item",
            thumbnail: nil,
            photo: nil,
            priority: 1,
            status: true,
            isNew: false,
            isPro: false,
            oldId: 0,
            children: [grandChild],
            customFields: nil
        )
        
        let parent = ItemStoreModel(
            id: "parent1",
            categoryId: "cat1",
            name: "Parent Item",
            thumbnail: nil,
            photo: nil,
            priority: 0,
            status: true,
            isNew: false,
            isPro: false,
            oldId: 0,
            children: [child],
            customFields: nil
        )
        
        // Test finding direct child
        let foundChild = parent.findChild(withId: "child1")
        XCTAssertNotNil(foundChild)
        XCTAssertEqual(foundChild?.name, "Child Item")
        
        // Test finding nested grandchild
        let foundGrandChild = parent.findChild(withId: "grandchild1")
        XCTAssertNotNil(foundGrandChild)
        XCTAssertEqual(foundGrandChild?.name, "Grandchild Item")
        
        // Test finding non-existent child
        let notFound = parent.findChild(withId: "nonexistent")
        XCTAssertNil(notFound)
    }
    
    func testJSONEncodingDecoding() throws {
        let child = ItemStoreModel(
            id: "child1",
            categoryId: "cat2",
            name: "Child Item",
            thumbnail: nil,
            photo: nil,
            priority: 1,
            status: true,
            isNew: false,
            isPro: false,
            oldId: 0,
            children: nil,
            customFields: nil
        )
        
        let parent = ItemStoreModel(
            id: "parent1",
            categoryId: "cat1",
            name: "Parent Item",
            thumbnail: "thumb1",
            photo: "photo1",
            priority: 0,
            status: true,
            isNew: true,
            isPro: true,
            oldId: 0,
            children: [child],
            customFields: ["key1": "value1"]
        )
        
        // Test JSON encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(parent)
        
        // Test JSON decoding
        let decoder = JSONDecoder()
        let decodedParent = try decoder.decode(ItemStoreModel.self, from: data)
        
        // Verify decoded object
        XCTAssertEqual(decodedParent.id, parent.id)
        XCTAssertEqual(decodedParent.name, parent.name)
        XCTAssertEqual(decodedParent.children?.count, parent.children?.count)
        XCTAssertEqual(decodedParent.children?.first?.id, parent.children?.first?.id)
        XCTAssertEqual(decodedParent.customFields?["key1"], parent.customFields?["key1"])
    }
}
