# Borrowing Module Implementation

## Overview
The borrowing module implements a complete book borrowing and returning system following FR2 (create borrow records) and FR3 (return books) requirements. This implementation follows the established patterns from the readers and books modules, using Riverpod for state management and role-based access control.

## Features Implemented

### FR2: Lập phiếu mượn sách (Create Borrow Records)
- **Role**: THUTHU (Librarian) only
- **Functionality**: Create new borrow records with validation
- **Validation**: 
  - Check if reader has active borrows (one book at a time rule)
  - Check if book copy is already borrowed
  - Automatic due date calculation
- **UI**: Modal dialog with form validation and loading states

### FR3: Ghi nhận trả sách (Return Books)
- **Role**: THUTHU (Librarian) only at their branch
- **Functionality**: Mark books as returned with optional notes
- **Features**:
  - Display borrow details and overdue status
  - Validation before return
  - Update borrow record with return date
- **UI**: Confirmation dialog with book information display

### Role-Based Access Control
- **THUTHU (Librarian)**:
  - View borrow records for their branch
  - Create new borrow records
  - Process book returns
  - Search and filter local records

- **QUANLY (Manager)**:
  - View borrow records across all branches
  - Monitor system-wide borrowing statistics
  - Cannot create/return books (read-only access)

## File Structure

```
lib/presentation/borrowing/
├── borrow_page.dart                 # Main borrowing interface
├── providers/
│   └── borrowing_provider.dart      # State management with Riverpod
└── widgets/
    ├── borrow_create_dialog.dart    # FR2: Create borrow record dialog
    ├── borrow_records_table.dart    # Display borrow records with pagination
    └── return_book_dialog.dart      # FR3: Return book dialog
```

## Technical Implementation

### State Management (Riverpod)
- **BorrowRecordsProvider**: Manages borrow records with pagination and search
- **CreateBorrowRecordProvider**: Handles new borrow record creation (FR2)
- **ReturnBookProvider**: Handles book return operations (FR3)
- **Validation Providers**: Check reader/book status before operations
- **Pagination State**: Manages table pagination with search functionality

### Data Flow
1. **Authentication Check**: Verify user role and permissions
2. **Branch Context**: Determine current library branch for THUTHU users
3. **Data Fetching**: Load borrow records with pagination and filtering
4. **CRUD Operations**: Create borrow records and process returns
5. **Real-time Updates**: Refresh data after operations

### UI Components
- **Responsive Table**: Display borrow records with role-based columns
- **Search Interface**: Real-time search with debouncing
- **Action Buttons**: Context-aware actions based on user role
- **Modal Dialogs**: Form-based interactions for create/return operations
- **Status Indicators**: Visual status chips (borrowed, returned, overdue)

### Data Entities Used
- `BorrowRecordWithDetailsEntity`: Extended borrow record with book and reader details
- `CreateBorrowRequestEntity`: Request model for creating new borrows
- `UserInfoEntity`: User authentication and role information
- `PagingEntity`: Pagination metadata

## Validation Rules

### Create Borrow Record (FR2)
1. Reader ID must be valid and exist in system
2. Reader cannot have any active borrows (one book at a time)
3. Book copy ID must be valid and available
4. Book copy must not be currently borrowed
5. THUTHU can only create records for their branch

### Return Book (FR3)
1. Borrow record must exist and be active
2. Book must not be already returned
3. THUTHU can only return books from their branch
4. Return date is automatically set to current timestamp

## Error Handling
- **Validation Errors**: Client-side validation with server confirmation
- **Network Errors**: Graceful degradation with retry mechanisms
- **Permission Errors**: Role-based access control enforcement
- **User Feedback**: Toast notifications for success/error states
- **Loading States**: Visual indicators during async operations

## Integration Points

### Dependencies
- `borrowing_usecase.dart`: Business logic layer
- `borrow_repository.dart`: Data access layer
- `auth_provider.dart`: Authentication and user context
- `app_provider.dart`: Global application state (library site)

### Backend Integration
- Uses distributed query system for cross-branch data
- Implements horizontal fragmentation for site-based data
- Handles real-time updates for borrowing status changes

## Performance Considerations
- **Pagination**: Efficient data loading with configurable page sizes
- **Search Debouncing**: Prevents excessive API calls during search
- **State Caching**: Riverpod providers cache data with smart invalidation
- **Lazy Loading**: Components load data only when needed

## Testing Considerations
- Role-based access control scenarios
- Validation rule enforcement
- Pagination and search functionality
- Error handling and recovery
- Cross-branch data consistency

## Future Enhancements
- Notification system for overdue books
- Bulk operations for multiple books
- Advanced search filters (date ranges, status, etc.)
- Export functionality for reports
- Mobile-responsive optimizations

## Usage Examples

### For THUTHU (Librarian)
1. Navigate to borrowing page
2. View active borrow records for their branch
3. Click "Lập phiếu mượn" to create new borrow record
4. Enter reader ID and book copy ID
5. Click "Trả sách" button to process returns
6. Use search to find specific records

### For QUANLY (Manager)
1. Navigate to borrowing page
2. View system-wide borrowing statistics
3. Search across all branches
4. Monitor overdue books across system
5. Generate reports and analytics

This implementation provides a comprehensive borrowing management system that meets all functional requirements while maintaining consistency with the existing codebase architecture.
