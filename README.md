# Fidra Data Module

Module này cung cấp các chức năng quản lý dữ liệu cho ứng dụng Fidra, bao gồm upload file, quản lý bucket dữ liệu và lưu trữ.

## Các thành phần chính

1. **UploadRepository**
   - Xử lý quá trình upload file lên server
   - [Xem chi tiết](Sources/FidraData/UploadRepository.swift)

2. **DatabucketRepository**
   - Quản lý các bucket dữ liệu
   - [Xem chi tiết](Sources/FidraData/DatabucketRepository.swift)

3. **StoreRepository**
   - Xử lý lưu trữ dữ liệu cục bộ
   - [Xem chi tiết](Sources/FidraData/StoreRepository.swift)

### Custom Fields - `minAppVersion`

StoreRepository hỗ trợ filter categories và items theo phiên bản app thông qua custom field `minAppVersion`.

**Cách hoạt động:**
- Mỗi category/item trên server có thể chứa `customFields["minAppVersion"]` (ví dụ: `"1.5.0"`)
- Khi lấy data, StoreRepository tự động so sánh `minAppVersion` với version app hiện tại (`CFBundleShortVersionString`)
- Nếu version app < `minAppVersion` → category/item đó bị loại khỏi kết quả
- Nếu không có `minAppVersion` → category/item luôn được hiển thị

**Version comparison:**
- Sử dụng semantic versioning: so sánh từng segment (major.minor.patch)
- Segment thiếu được coi là `0` (ví dụ: `"1.2"` tương đương `"1.2.0"`)

**Ví dụ cấu hình trên server:**
```json
{
  "custom_fields": {
    "minAppVersion": "2.0.0"
  }
}
```
→ Chỉ app version >= 2.0.0 mới thấy content này.

**Các hàm được áp dụng filter:**
- `getCategories(parentId:...)` — filter categories
- `getItems(categoryId:...)` — filter items
- `getItemsWithPaging(categoryId:page:size:...)` — filter items (lưu ý: count trả về có thể < `size` do bị filter)

**Lưu ý:** Filter được áp dụng ở tất cả các nguồn data: cache, API remote, và fallback default repository.

## Kiến trúc tổng quan

Module FidraData được thiết kế theo mô hình repository, mỗi repository đảm nhận một chức năng cụ thể và có thể hoạt động độc lập. Các repository chia sẻ chung dịch vụ API thông qua ApiServerService.
