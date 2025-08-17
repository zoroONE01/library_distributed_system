# Triển khai Màn hình Quản lý Độc giả (Readers)

## Tổng quan

Đã triển khai đầy đủ màn hình quản lý độc giả theo yêu cầu FR8 và FR11 trong requirement.md, với kiểm soát truy cập dựa trên vai trò người dùng.

## Các file đã triển khai

### 1. Provider Layer (`providers/readers_provider.dart`)

- **ReadersProvider**: Provider chính quản lý state của danh sách độc giả
- **ReadersEntity**: Entity wrapper cho danh sách độc giả và pagination
- **Các provider phụ trợ**:
  - `readerById`: Lấy thông tin độc giả theo ID
  - `readersWithStats`: Lấy độc giả kèm thống kê
  - `searchReadersSystemWide`: Tìm kiếm toàn hệ thống (FR11)
  - `createReader`: Tạo độc giả mới (FR8)
  - `updateReader`: Cập nhật thông tin độc giả (FR8)
  - `deleteReader`: Xóa độc giả (FR8)

### 2. Main Page (`reader_list_page.dart`)

- **Giao diện chính** hiển thị danh sách độc giả
- **Kiểm soát truy cập theo vai trò**:
  - THUTHU: Chỉ thấy độc giả ở chi nhánh của mình, có thể CRUD
  - QUANLY: Thấy toàn hệ thống, chỉ xem (theo yêu cầu)
- **Chức năng tìm kiếm** với debounce
- **Tự động refresh** sau các thao tác CRUD

### 3. Table Widget (`widgets/readers_table.dart`)

- **Hiển thị dữ liệu** trong bảng với pagination
- **Cột hiển thị**:
  - STT
  - Mã độc giả
  - Họ và tên
  - Chi nhánh đăng ký
  - Hành động (chỉ cho THUTHU)
- **Role-based actions**: Chỉ THUTHU mới có nút Edit/Delete

### 4. Create Dialog (`reader_list_create_dialog.dart`)

- **Form tạo độc giả mới** (chỉ cho THUTHU)
- **Tự động gán chi nhánh**: Theo chi nhánh của thủ thư hiện tại
- **Validation**: Kiểm tra mã độc giả và họ tên
- **Integration**: Tích hợp với provider để tạo và refresh danh sách

### 5. Edit Dialog (`widgets/reader_edit_dialog.dart`)

- **Form chỉnh sửa thông tin độc giả**
- **Ràng buộc phân mảnh**: Không cho phép thay đổi mã độc giả và chi nhánh đăng ký
- **Conditional UI**: Khóa các field không được phép thay đổi khi edit
- **Error handling**: Xử lý lỗi và hiển thị thông báo

## Yêu cầu chức năng đã đáp ứng

### FR8: CRUD Độc giả (THUTHU)

✅ **Tạo mới**: Thủ thư có thể tạo độc giả mới tại chi nhánh của mình

- Tự động gán `MaCN_DangKy` là chi nhánh của thủ thư
- Validation đầy đủ cho mã độc giả và họ tên

✅ **Cập nhật**: Thủ thư có thể sửa thông tin độc giả

- Không được thay đổi `MaCN_DangKy` (khóa phân mảnh)
- Không được thay đổi mã độc giả

✅ **Xóa**: Thủ thư có thể xóa độc giả

- Chỉ được xóa nếu độc giả không có phiếu mượn đang hoạt động
- Confirmation dialog để xác nhận

✅ **Tra cứu**: Thủ thư có thể tìm kiếm độc giả trong phạm vi chi nhánh

### FR11: Tra cứu toàn hệ thống (QUANLY)

✅ **Xem toàn hệ thống**: Quản lý có thể xem độc giả từ tất cả chi nhánh
✅ **Tìm kiếm hệ thống**: Provider `searchReadersSystemWide` hỗ trợ tìm kiếm trên toàn hệ thống
✅ **View-only**: Quản lý chỉ được xem, không có quyền CRUD độc giả

## Kiến trúc và Pattern

### 1. Role-Based Access Control

```dart
// Chỉ THUTHU mới có nút tạo
if (userInfo.role == UserRole.librarian)
  AppButton(label: 'Thêm độc giả mới', ...)

// Chỉ THUTHU mới có actions trong table
if (userInfo.role == UserRole.librarian) {
  children.add(ActionButtons(...));
}
```

### 2. Fragmentation Key Protection

```dart
// Không cho phép thay đổi khóa phân mảnh khi edit
enabled: false, // Chi nhánh đăng ký
readOnly: _isEditing, // Mã độc giả
```

### 3. Provider Pattern với Riverpod

```dart
@riverpod
class Readers extends _$Readers {
  // Auto-refresh và state management
}

// Các provider cho từng operation
@riverpod Future<void> createReader(...)
@riverpod Future<void> updateReader(...)
@riverpod Future<void> deleteReader(...)
```

### 4. Error Handling

```dart
try {
  await ref.read(createReaderProvider(reader).future);
  // Success feedback
} catch (e) {
  // Error feedback với SnackBar
}
```

## Tích hợp với Backend

Các provider sử dụng:

- `ReadersRepository` để gọi API
- `GetReadersUseCase` cho danh sách có phân trang
- `CreateReaderUseCase` cho tạo mới
- `UpdateReaderUseCase` cho cập nhật
- `DeleteReaderUseCase` cho xóa
- `SearchReadersSystemWideUseCase` cho tìm kiếm toàn hệ thống

## Responsive Design

- **Table responsive**: Sử dụng `AppTable` với column widths linh hoạt
- **Dialog responsive**: Fixed width cho form, adaptive cho mobile
- **Button spacing**: Consistent với design system

## Testing và Validation

- **Form validation**: Comprehensive cho tất cả input fields
- **Error handling**: Try-catch cho tất cả async operations
- **User feedback**: SnackBar cho success/error messages
- **Loading states**: AsyncValue handling trong provider

## Next Steps

1. **Unit Tests**: Viết tests cho providers và business logic
2. **Integration Tests**: Test end-to-end workflows
3. **Performance**: Optimize cho large datasets
4. **Accessibility**: Thêm semantic labels và screen reader support
