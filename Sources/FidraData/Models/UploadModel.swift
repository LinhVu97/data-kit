import Foundation

public struct UploadModel: Codable {
    public let id: String
    public let appKey: String
    public let region: String
    public let key: String
    public let name: String
    public let size: Int
    public let ext: String
    public let mimeType: String
    public let uploadId: String
    public let partSplitSize: Int
    public let uploadLinks: [UploadLink]
    public let creatorId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case appKey = "app_key"
        case region
        case key
        case name
        case size
        case ext
        case mimeType = "mime_type"
        case uploadId = "upload_id"
        case partSplitSize = "part_split_size"
        case uploadLinks = "upload_links"
        case creatorId = "creator_id"
    }
    
    public struct UploadLink: Codable {
        public let link: String
        public let partIdx: Int
        
        enum CodingKeys: String, CodingKey {
            case link
            case partIdx = "part_idx"
        }
    }
}

public struct UploadedPart {
    public let etag: String
    public let partIdx: Int
    
    public init(etag: String, partIdx: Int) {
        self.etag = etag
        self.partIdx = partIdx
    }
}

public struct UploadSuccessModel: Codable {
    public let id: String
    public let appKey: String
    public let region: String
    public let bucketName: String
    public let key: String
    public let name: String
    public let size: Int
    public let ext: String
    public let mimeType: String
    public let thumbnail: String
    public let linkCdn: String
    public let accessHash: String
    public let attributes: String
    public let creatorId: String
    public let createdTime: Int
    public let updatedTime: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case appKey = "app_key"
        case region
        case bucketName = "bucket_name"
        case key
        case name
        case size
        case ext
        case mimeType = "mime_type"
        case thumbnail
        case linkCdn = "link_cdn"
        case accessHash = "access_hash"
        case attributes
        case creatorId = "creator_id"
        case createdTime = "created_time"
        case updatedTime = "updated_time"
    }
}
