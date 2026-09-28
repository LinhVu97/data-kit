//
//  ApiServerModel.swift
//  FidraCore
//
//  Created by hi on 24/2/25.
//
import Foundation

public enum ApiError: Error {
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(Int, String)
}

public struct BaseResponse<T>: Decodable where T: Decodable {
    public let message: String
    public let data: T?
    public let status: Int
}

public struct PagingResponse: Decodable {
    public let nextOffset: Int?
    public let limit: Int?
    public let total: Int?
    public let currentPage: Int?
    public let pageSize: Int?
    public let nextPage: Int?
    public let totalPages: Int?
    public let hasNext: Bool?
    
    enum CodingKeys: String, CodingKey {
        case nextOffset = "next_offset"
        case limit = "limit"
        case total = "total"
        case currentPage = "current_page"
        case pageSize = "page_size"
        case nextPage = "next_page"
        case totalPages = "total_pages"
        case hasNext =  "has_next"
    }
    
    public init(nextOffset: Int?, limit: Int?, total: Int?, currentPage: Int?, pageSize: Int?, nextPage: Int?, totalPages: Int?, hasNext: Bool? = false) {
        self.nextOffset = nextOffset
        self.limit = limit
        self.total = total
        self.currentPage = currentPage
        self.pageSize = pageSize
        self.nextPage = nextPage
        self.totalPages = totalPages
        self.hasNext = hasNext
    }
}

public struct BaseListResponse<T>: Decodable where T: Decodable {
    public let message: String
    public let data: [T]?
    public let dataExtend: String?
    public let status: Int
    public let paging: PagingResponse?
    
    enum CodingKeys: String, CodingKey {
        case message
        case data
        case dataExtend = "data_extend"
        case status
        case paging
    }
}

public struct ItemStoreModel: Codable, Equatable, Hashable, Identifiable, MinAppVersionFilterable  {
    public static func from(json: [String: Any]) -> ItemStoreModel? {
        guard let id = json["id"] as? String,
              let categoryId = json["category_id"] as? String,
              let name = json["name"] as? String else {
            return nil
        }
        
        let priority = json["priority"] as? Int ?? 0
        let status = json["status"] as? Bool ?? true
        let isNew = json["is_new"] as? Bool ?? false
        let isPro = json["is_pro"] as? Bool ?? false
        let oldId = json["old_id"] as? Int ?? 0
        let createdTime = json["created_time"] as? Int ?? 0
        let children = json["children"] as? [ItemStoreModel]
        
        return ItemStoreModel(
            id: id,
            categoryId: categoryId,
            name: name,
            thumbnail: json["thumbnail"] as? String,
            photo: json["photo"] as? String,
            priority: priority,
            status: status,
            isNew: isNew,
            isPro: isPro,
            oldId: oldId,
            children: children,
            createdTime: createdTime,
            customFields: json["custom_fields"] as? [String: String]
        )
    }
    public let id: String
    public let categoryId: String
    public let name: String
    public let thumbnail: String?
    public let photo: String?
    public let priority: Int 
    public let status: Bool 
    public let isNew: Bool 
    public var isPro: Bool
    public let oldId: Int
    public let createdTime: Int
    public let children: [ItemStoreModel]?
    public let customFields: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case categoryId = "category_id"
        case name
        case thumbnail
        case photo
        case priority
        case status
        case isNew = "is_new"
        case isPro = "is_pro"
        case oldId = "old_id"
        case children
        case createdTime = "created_time"
        case customFields = "custom_fields"
    }

    public init(id: String, categoryId: String, name: String, thumbnail: String?, photo: String?,
                priority: Int, status: Bool, isNew: Bool, isPro: Bool, oldId: Int = 0, children: [ItemStoreModel]?, createdTime: Int? = 0, customFields: [String: String]?) {
        self.id = id
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
        self.createdTime = createdTime ?? 0
        self.customFields = customFields
    }
    
    public init(id: String, name: String) {
        self.id = id
        self.categoryId = ""
        self.name = name
        self.thumbnail = ""
        self.photo = ""
        self.priority = 0
        self.status = false
        self.isNew = false
        self.isPro = false
        self.oldId = 0
        self.children = nil
        self.createdTime = 0
        self.customFields = nil
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        categoryId = try container.decode(String.self, forKey: .categoryId)
        name = try container.decode(String.self, forKey: .name)
        thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail)
        photo = try container.decodeIfPresent(String.self, forKey: .photo)
        priority = try container.decodeIfPresent(Int.self, forKey: .priority) ?? 0
        status = try container.decodeIfPresent(Bool.self, forKey: .status) ?? true
        isNew = try container.decodeIfPresent(Bool.self, forKey: .isNew) ?? false
        isPro = try container.decodeIfPresent(Bool.self, forKey: .isPro) ?? false
        oldId = try container.decodeIfPresent(Int.self, forKey: .oldId) ?? 0
        children = try container.decodeIfPresent([ItemStoreModel].self, forKey: .children)
        createdTime = try container.decodeIfPresent(Int.self, forKey: .createdTime) ?? 0
        customFields = try container.decodeIfPresent([String: String].self, forKey: .customFields)
    }
}

// MARK: - ItemStoreModel Extensions
extension ItemStoreModel {
    /// Check if the item has any children
    public var hasChildren: Bool {
        return children != nil && !children!.isEmpty
    }
    
    /// Get all children items recursively (flattened)
    public var allChildren: [ItemStoreModel] {
        guard let children = children else { return [] }
        
        var allItems: [ItemStoreModel] = []
        for child in children {
            allItems.append(child)
            allItems.append(contentsOf: child.allChildren)
        }
        return allItems
    }
    
    /// Get the total count of all items including children
    public var totalItemCount: Int {
        return 1 + allChildren.count
    }
    
    /// Find a specific child item by ID
    public func findChild(withId id: String) -> ItemStoreModel? {
        guard let children = children else { return nil }
        
        for child in children {
            if child.id == id {
                return child
            }
            if let found = child.findChild(withId: id) {
                return found
            }
        }
        return nil
    }
}

public struct DictionaryResponse: Codable {
    private let storage: [String: AnyCodable]
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        var dict: [String: AnyCodable] = [:]
        for key in container.allKeys {
            dict[key.stringValue] = try container.decode(AnyCodable.self, forKey: key)
        }
        self.storage = dict
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        for (key, value) in storage {
            let codingKey = DynamicCodingKeys(stringValue: key)!
            try container.encode(value, forKey: codingKey)
        }
    }
    
    public func toDictionary() -> [String: Any] {
        return storage.mapValues { $0.value }
    }
}

private struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
    }
}

public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded"))
        }
    }
}

/// Protocol for models that support filtering by minimum app version.
///
/// Models conforming to this protocol expose `customFields` which may contain
/// a `"minAppVersion"` key (e.g. `"1.5.0"`). When set, the item/category
/// will only be returned to apps with a version >= `minAppVersion`.
///
/// Supported custom field key: `"minAppVersion"` — semantic version string (e.g. "1.2.3").
/// If not present or empty, the item is available to all app versions.
public protocol MinAppVersionFilterable {
    var customFields: [String: String]? { get }
}

extension MinAppVersionFilterable {
    public var minAppVersion: String? {
        customFields?["minAppVersion"]
    }
    
    public var minIOSVersion: String? {
        customFields?["minIOSVersion"]
    }
}

public struct CategoryStoreModel: Codable,Equatable, Hashable, Identifiable, MinAppVersionFilterable {
    public static func from(json: [String: Any]) -> CategoryStoreModel? {
        guard let id = json["id"] as? String,
              let name = json["name"] as? String else {
            return nil
        }
        
        return CategoryStoreModel(
            id: id,
            parentId: json["parent_id"] as? String,
            priority: json["priority"] as? Int,
            name: name,
            status: json["status"] as? Bool,
            thumbnail: json["thumbnail"] as? String,
            photo: json["photo"] as? String,
            isNew: json["is_new"] as? Bool,
            isPro: json["is_pro"] as? Bool,
            oldId: json["old_id"] as? Int,
            createdTime: json["created_time"] as? Int,
            customFields: json["custom_fields"] as? [String: String]
        )
    }
    public let id: String
    public let parentId: String?
    public let priority: Int
    public let name: String
    public let status: Bool
    public let thumbnail: String?
    public let photo: String?
    public let isNew: Bool
    public let isPro: Bool
    public let oldId: Int
    public let createdTime: Int
    public let customFields: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case parentId = "parent_id"
        case priority
        case name
        case status
        case thumbnail
        case photo
        case isNew = "is_new"
        case isPro = "is_pro"
        case oldId = "old_id"
        case createdTime = "created_time"
        case customFields = "custom_fields"
    }

    public init(id: String, parentId: String?, priority: Int?, name: String?, status: Bool?, thumbnail: String?, photo: String?, isNew: Bool?, isPro: Bool?, oldId: Int? = 0, createdTime: Int? = 0, customFields: [String: String]?) {
        self.id = id
        self.parentId = parentId
        self.priority = priority ?? 0
        self.name = name ?? ""
        self.status = status ?? true
        self.thumbnail = thumbnail
        self.photo = photo
        self.isNew = isNew ?? false
        self.isPro = isPro ?? false
        self.oldId = oldId ?? 0
        self.createdTime = createdTime ?? 0
        self.customFields = customFields
    }
    
    public init(id: String, name: String) {
        self.id = id
        self.parentId = nil
        self.priority = 0
        self.name = name
        self.status = true
        self.thumbnail = ""
        self.photo = ""
        self.isNew = false
        self.isPro =  false
        self.oldId =  0
        self.createdTime =  0
        self.customFields = nil
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        name = try container.decode(String.self, forKey: .name)
        thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail)
        photo = try container.decodeIfPresent(String.self, forKey: .photo)
        priority = try container.decodeIfPresent(Int.self, forKey: .priority) ?? 0
        status = try container.decodeIfPresent(Bool.self, forKey: .status) ?? true
        isNew = try container.decodeIfPresent(Bool.self, forKey: .isNew) ?? false
        isPro = try container.decodeIfPresent(Bool.self, forKey: .isPro) ?? false
        oldId = try container.decodeIfPresent(Int.self, forKey: .oldId) ?? 0
        createdTime = try container.decodeIfPresent(Int.self, forKey: .createdTime) ?? 0
        customFields = try container.decodeIfPresent([String: String].self, forKey: .customFields)
    }
}
