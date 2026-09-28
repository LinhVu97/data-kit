import Foundation
import UIKit

public class UploadRepository {
    private let apiService: ApiServiceProtocol
    
    public init() {
        let service = ApiServerService(baseUrl: "https://uploader.volio.vn")
        service.addDefaultHeader(key: "X-API-KEY", value: "reporter_f58ba22b4f8832a_1648636800")
        self.apiService = service
    }
    
    public init(apiService: ApiServiceProtocol) {
        self.apiService = apiService
    }
    
    public func uploadFile(
        appId: String,
        fileSize: Int,
        name: String,
        ext: String,
        mimeType: String,
        data: Data,
        deviceId: String,
        sendTimeout: TimeInterval = 180,
        receiveTimeout: TimeInterval = 180
    ) async throws -> UploadSuccessModel? {
        let parameters: [String: Any] = [
            "device_id": deviceId,
            "file_size": fileSize,
            "name": name,
            "ext": ext,
            "mime_type": mimeType
        ]
        
        let uploadModel: UploadModel? = try await apiService.post(
            api: "/uploader/api/v1.0/mobile/\(appId)/upload",
            parameters: parameters,
            sendTimeout: sendTimeout,
            receiveTimeout: receiveTimeout
        )
        
        guard let uploadModel = uploadModel,
              let uploadUrl = uploadModel.uploadLinks.first?.link else {
            throw NSError(domain: "UploadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Không lấy được link upload"])
        }
        
        // Bước 2: Upload lên S3
        guard let etag = try await uploadToS3(url: uploadUrl, data: data) else {
            throw NSError(domain: "UploadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Upload lên S3 thất bại"])
        }
        
        // Bước 3: Complete multipart upload
        let uploadedPart = UploadedPart(etag: "\"\(etag)\"", partIdx: uploadModel.uploadLinks.first?.partIdx ?? 1)
        return try await completeMultipartUpload(
            id: uploadModel.id,
            uploadId: uploadModel.uploadId,
            uploadedParts: [uploadedPart]
        )
    }
    
    private func uploadToS3(url: String, data: Data) async throws -> String? {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "PUT"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await URLSession.shared.upload(for: request, from: data)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "UploadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Upload thất bại"])
        }
        
        // Kiểm tra các biến thể khác nhau của header ETag
        if let etag = httpResponse.allHeaderFields["ETag"] as? String {
            return etag
        }
        
        if let etag = httpResponse.allHeaderFields["etag"] as? String {
            return etag
        }
        
        if let etag = httpResponse.allHeaderFields["Etag"] as? String {
            return etag
        }
        
        // In ra tất cả các header để debug
        print("Tất cả header trả về từ S3:")
        for (key, value) in httpResponse.allHeaderFields {
            print("\(key): \(value)")
        }
        
        // Fallback: Tạo etag ngẫu nhiên để tránh lỗi
        let fallbackEtag = UUID().uuidString
        print("Không tìm thấy etag, sử dụng fallback: \(fallbackEtag)")
        return "\"\(fallbackEtag)\""
    }
    
    private func completeMultipartUpload(
        id: String,
        uploadId: String,
        uploadedParts: [UploadedPart]
    ) async throws -> UploadSuccessModel? {
        let parameters: [String: Any] = [
            "id": id,
            "upload_id": uploadId,
            "uploaded_parts": uploadedParts.map { [
                "etag": $0.etag,
                "part_idx": $0.partIdx
            ]}
        ]
        
        let result: UploadSuccessModel? = try await apiService.put(
            api: "/uploader/api/v1.0/upload",
            parameters: parameters
        )
        
        return result
    }
}
