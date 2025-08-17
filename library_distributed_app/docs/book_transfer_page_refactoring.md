# Book Transfer Page Refactoring

## Tóm tắt
Tách tính năng chuyển sách thành một trang riêng biệt thay thế cho trang "Branches" để tối ưu hóa trải nghiệm người dùng và tập trung vào chức năng chính.

## Lý do tái cấu trúc

### Vấn đề ban đầu
- Trang "Branches" không có chức năng thực tế, chỉ là placeholder
- Tính năng chuyển sách bị ẩn trong trang "Mượn sách", khó truy cập
- Không tận dụng được navigation rail cho chức năng quan trọng của QUANLY

### Giải pháp
- Thay thế trang "Branches" bằng "Book Transfer Page" 
- Tạo một trang chuyên biệt cho chức năng chuyển sách giữa các site
- Cải thiện khả năng tiếp cận cho vai trò QUANLY

## Thay đổi thực hiện

### 1. Tạo BookTransferPage mới

**File:** `/lib/presentation/book_transfer/book_transfer_page.dart`

**Tính năng chính:**
- Giao diện chuyên biệt cho chuyển sách
- Kiểm tra quyền truy cập (chỉ QUANLY)
- Tìm kiếm sách có thể chuyển
- Hiển thị danh sách sách theo site
- Tích hợp dialog chuyển sách

**Thành phần UI:**
```dart
// Header với nút "Chuyển sách mới"
_buildHeader(context)

// Tìm kiếm và danh sách sách
_buildContent(context)
  ├── _buildSearchRow(context)
  └── _buildTransferableBooksList(context)
      └── _buildBooksTable(context, books)
```

### 2. Cập nhật Router

**File:** `/lib/router/routes.dart`

**Thay đổi:**
```dart
// Cũ
TypedStatefulShellBranch<StatefulShellBranchData>(
  routes: <TypedGoRoute<BranchesRoute>>[
    TypedGoRoute<BranchesRoute>(path: '/branches'),
  ],
)

// Mới  
TypedStatefulShellBranch<StatefulShellBranchData>(
  routes: <TypedGoRoute<BookTransferRoute>>[
    TypedGoRoute<BookTransferRoute>(path: '/book-transfer'),
  ],
)
```

**Route mới:**
```dart
@TypedGoRoute<BookTransferRoute>(path: '/book-transfer')
class BookTransferRoute extends GoRouteData {
  const BookTransferRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const BookTransferPage();
}
```

### 3. Cập nhật NavigationRail

**File:** `/lib/presentation/main/main_page.dart`

**Thay đổi:**
```dart
// Cũ
NavigationRailDestination(
  icon: Icon(Icons.bar_chart_rounded),
  label: Text('Chi nhánh'),
)

// Mới
NavigationRailDestination(
  icon: Icon(Icons.transfer_within_a_station_rounded),
  label: Text('Chuyển sách'),
)
```

### 4. Cập nhật BorrowPage

**File:** `/lib/presentation/borrowing/borrow_page.dart`

**Thay đổi:**
- Xóa nút "Chuyển sách" khỏi header
- Xóa method `_showTransferDialog`
- Xóa import `book_transfer_dialog.dart`
- Cập nhật comment để phản ánh chức năng chính xác

### 5. Xóa Branches cũ

**Hành động:**
- Xóa thư mục `/lib/presentation/branches/`
- Xóa import `branchs_page.dart` khỏi router
- Xóa `BranchesRoute` definition

## Lợi ích của việc tái cấu trúc

### 1. Trải nghiệm người dùng tốt hơn
- **Truy cập trực tiếp:** QUANLY có thể truy cập chức năng chuyển sách từ navigation rail
- **Giao diện chuyên biệt:** Trang riêng cho chức năng chuyển sách với đầy đủ tính năng
- **Tìm kiếm nâng cao:** Có thể tìm kiếm và duyệt sách trước khi chuyển

### 2. Kiến trúc tốt hơn
- **Tách biệt chức năng:** Mỗi trang có trách nhiệm rõ ràng
- **Tái sử dụng code:** BookTransferDialog vẫn có thể được sử dụng ở nơi khác
- **Dễ bảo trì:** Logic chuyển sách tập trung tại một nơi

### 3. Quyền truy cập rõ ràng
- **Kiểm tra vai trò:** Trang hiển thị thông báo rõ ràng nếu không có quyền
- **UI phù hợp:** Chỉ hiển thị cho QUANLY, ẩn khỏi THUTHU

## Cấu trúc component

```
BookTransferPage
├── Auth & Role Check (getUserInfoProvider)
├── Header Section
│   ├── Title: "Quản lý chuyển sách giữa các site"
│   └── "Chuyển sách mới" Button
├── Content Section
│   ├── Search Row
│   │   ├── Search TextField (debounced)
│   │   ├── Clear Button (conditional)
│   │   └── Refresh Button
│   └── Transferable Books List
│       ├── Search Results Display
│       ├── Books Table
│       │   ├── ISBN Column
│       │   ├── Book Title Column
│       │   ├── Current Site Chip
│       │   ├── Status Column
│       │   └── Transfer Action Button
│       └── Empty State Message
└── BookTransferDialog Integration
```

## State Management

**Providers sử dụng:**
- `getUserInfoProvider` - Kiểm tra thông tin và quyền người dùng
- `transferableBookCopiesProvider` - Quản lý danh sách sách có thể chuyển
- `transferBookCopyProvider` - Thực hiện giao dịch chuyển sách

**Provider methods:**
```dart
// Tìm kiếm sách
transferableBookCopiesProvider.notifier.search(query)

// Xóa kết quả tìm kiếm
transferableBookCopiesProvider.notifier.clear()

// Thực hiện chuyển sách (trong dialog)
transferBookCopyProvider(request)
```

## Testing Guidelines

### 1. Role-based Access Testing
```dart
// Test QUANLY access
testWidgets('should allow QUANLY to access book transfer page', (tester) async {
  // Mock QUANLY user
  // Navigate to /book-transfer
  // Verify page content is displayed
});

// Test THUTHU restriction  
testWidgets('should restrict THUTHU from book transfer page', (tester) async {
  // Mock THUTHU user
  // Navigate to /book-transfer
  // Verify access denied message
});
```

### 2. Search Functionality Testing
```dart
testWidgets('should search transferable books with debounce', (tester) async {
  // Enter search query
  // Wait for debounce delay
  // Verify provider method called
  // Verify results displayed
});
```

### 3. Navigation Testing
```dart
testWidgets('should navigate to book transfer page from navigation rail', (tester) async {
  // Tap on "Chuyển sách" navigation item
  // Verify route change to /book-transfer
  // Verify page is displayed
});
```

## Deployment Notes

1. **Database Migration:** Không cần thay đổi database
2. **Backend:** Không cần thay đổi API endpoints
3. **Frontend:** Cần build lại router và providers
4. **Cache:** Router cache sẽ tự động cập nhật

## Future Enhancements

1. **Batch Transfer:** Chuyển nhiều quyển sách cùng lúc
2. **Transfer History:** Lịch sử các lần chuyển sách
3. **Advanced Filters:** Lọc theo tác giả, thể loại, năm xuất bản
4. **Transfer Analytics:** Thống kê các giao dịch chuyển sách
5. **Notification System:** Thông báo khi có sách được chuyển đến

## Kết luận

Việc tái cấu trúc tách riêng trang chuyển sách đã mang lại:
- ✅ Trải nghiệm người dùng tốt hơn cho QUANLY
- ✅ Kiến trúc ứng dụng rõ ràng và dễ bảo trì
- ✅ Tận dụng tối đa navigation rail
- ✅ Tập trung vào chức năng cốt lõi của distributed transaction
- ✅ Chuẩn bị tốt cho các tính năng mở rộng trong tương lai

Đây là một bước quan trọng trong việc hoàn thiện hệ thống quản lý thư viện phân tán với giao diện người dùng chuyên nghiệp và hiệu quả.
