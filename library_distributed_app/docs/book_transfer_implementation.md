# Tính năng Chuyển Sách giữa các Chi nhánh

## Tổng quan

Tính năng chuyển sách là một implementation của giao dịch phân tán (distributed transaction) sử dụng giao thức Two-Phase Commit (2PC) để chuyển quyển sách từ chi nhánh này sang chi nhánh khác trong hệ thống thư viện phân tán.

## Yêu cầu Chức năng

- **Vai trò:** Chỉ có QUANLY (Manager) mới được phép thực hiện chuyển sách
- **Phạm vi:** Chuyển quyển sách giữa các chi nhánh (Q1 ↔ Q3)
- **Điều kiện:** Quyển sách phải ở trạng thái "Có sẵn" (không đang được mượn)

## Kiến trúc Implementation

### 1. Domain Layer
- **Entities:** `BookTransferRequestEntity`, `BookTransferResponseEntity`, `BookCopyTransferInfoEntity`
- **Repository:** `BookTransferRepository` (interface)
- **Use Cases:** 
  - `TransferBookCopyUseCase`: Thực hiện chuyển sách với validation
  - `GetBookCopyTransferInfoUseCase`: Lấy thông tin quyển sách
  - `SearchTransferableBookCopiesUseCase`: Tìm kiếm sách có thể chuyển

### 2. Data Layer
- **Repository Implementation:** `BookTransferRepositoryImpl`
- **Services:** 
  - `CoordinatorService`: API gọi đến coordinator cho 2PC
  - `BookCopiesService`: Lấy thông tin quyển sách
  - `BooksService`: Lấy thông tin đầu sách

### 3. Presentation Layer
- **Provider:** `BookTransferProvider` với Riverpod state management
- **UI Dialog:** `BookTransferDialog` với search và validation
- **Integration:** Thêm vào `BorrowPage` cho QUANLY

## Distributed Transaction (2PC) Flow

### Phase 1: Prepare
1. **Source Site:** Kiểm tra quyển sách tồn tại và available
2. **Source Site:** Lock quyển sách (set status = "Đang chuyển")
3. **Destination Site:** Chuẩn bị nhận quyển sách mới
4. **Coordinator:** Đợi cả hai site confirm PREPARED

### Phase 2: Commit
1. **Source Site:** Xóa quyển sách khỏi database
2. **Destination Site:** Thêm quyển sách vào database  
3. **Coordinator:** Confirm transaction COMMITTED

### Rollback (nếu có lỗi)
- **Source Site:** Restore status quyển sách về "Có sẵn"
- **Destination Site:** Cleanup any prepared data
- **Coordinator:** Mark transaction as ABORTED

## API Endpoints

### Backend (Go)
- `POST /coordinator/transfer-book`: Main endpoint sử dụng 2PC
- `POST /manager/transfer`: Alternative endpoint for manager
- Stored Procedure: `sp_ChuyenSach` implements 2PC at database level

### Frontend (Flutter)
- Service call qua `CoordinatorService.transferBook()`
- Model: `TransferBookRequestModel` và `TransferBookResponseModel`

## User Interface

### Dialog Components
1. **Search Section:** 
   - Tìm kiếm theo tên sách, tác giả, mã sách
   - Hiển thị danh sách quyển sách available
   - Option nhập trực tiếp mã quyển sách

2. **Site Selection:**
   - Dropdown chọn chi nhánh nguồn và đích
   - Validation chi nhánh phải khác nhau
   - Auto-set chi nhánh nguồn dựa trên quyển sách đã chọn

3. **Transfer Confirmation:**
   - Hiển thị thông tin 2PC protocol
   - Preview thao tác sẽ thực hiện
   - Loading state và error handling

### Access Control
- Button "Chuyển sách" chỉ hiển thị cho QUANLY
- Integrated vào BorrowPage với role-based UI
- Authentication check ở provider level

## Technical Features

### State Management (Riverpod)
- `transferableBookCopiesProvider`: Cache search results
- `bookCopyTransferInfoProvider`: Book copy details
- `transferBookCopyProvider`: Execute transfer với error handling

### Validation
- Book copy existence và availability
- Site selection consistency  
- User role permission (QUANLY only)
- Network connectivity và service availability

### Error Handling
- Network errors với retry mechanism
- Business logic errors với user-friendly messages
- Transaction rollback trên distributed system
- UI state restoration after errors

## Database Impact

### Bảng QUYENSACH (Fragmented)
- **Source Site:** DELETE record cho quyển sách
- **Destination Site:** INSERT record mới với MaCN updated

### Audit Trail
- Transaction ID tracking
- Timestamp logging  
- Status change history
- Error logging for failed transactions

## Testing Scenarios

### Happy Path
1. Manager login và navigate to BorrowPage
2. Click "Chuyển sách" button
3. Search và select available book copy
4. Choose source và destination sites
5. Confirm transfer
6. Verify 2PC transaction completed
7. Verify book moved between sites

### Error Scenarios
1. **Book not available:** Already borrowed
2. **Network failure:** During 2PC phases
3. **Permission denied:** Non-manager user
4. **Site unavailable:** One site down during transfer
5. **Concurrent access:** Multiple transfers on same book

## Monitoring và Logging

### Transaction Monitoring
- 2PC phase completion status
- Site response times
- Error rates và types
- Transaction success/failure metrics

### Performance Metrics
- Average transfer completion time
- Database lock duration
- Network latency between sites
- User interaction completion rates

## Security Considerations

### Authentication
- JWT token validation for API calls
- Session management for long-running transfers
- Role-based access control enforcement

### Data Integrity
- Atomic transactions across sites
- Consistent state even with partial failures
- Idempotent operations for retry safety

## Future Enhancements

### Potential Improvements
1. **Batch Transfer:** Multiple books cùng lúc
2. **Scheduled Transfer:** Automation based on demand
3. **Transfer History:** Audit log for all transfers
4. **Notification System:** Real-time updates cho staff
5. **Mobile Support:** Transfer from mobile app

### Scalability
- Support for more than 2 sites
- Load balancing for coordinator service
- Distributed coordinator for high availability
- Async processing for large transfers
