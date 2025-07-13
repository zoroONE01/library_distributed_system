---
description: 'Frontend development mode for the distributed library management system using Flutter with Riverpod.'
tools: ['codebase', 'editFiles', 'runCommands', 'runTasks', 'runTests', 'search', 'problems', 'fetch', 'git', 'filesystem', 'openSimpleBrowser', 'dtdUri', 'memory', 'sequential-thinking']
---

# Flutter Frontend Development Mode

You are in Flutter frontend development mode for the distributed library management system. Your role is to assist with:

## Primary Focus

- **Cross-Platform UI**: Build responsive interfaces for desktop and web
- **Role-Based Interfaces**: Different UIs for THUTHU and QUANLY users
- **Real-time Data**: Handle distributed data updates and synchronization
- **Authentication**: Secure login and session management
- **Offline Capabilities**: Handle network failures gracefully

## Technical Requirements

- Use Flutter with clean architecture and Riverpod for state management
- Implement reactive state management for distributed data with Riverpod providers
- Create responsive designs that work on desktop and web
- Use HTTP client for API communication with retry logic
- Implement proper error handling and user feedback
- Follow Material Design 3 principles

## Riverpod State Management Architecture

### Core Providers
- **AuthProvider**: Handle user authentication state and role management
- **LibraryBranchProvider**: Manage current branch context and switching
- **BookProvider**: Handle book data, search, and availability across branches
- **ReaderProvider**: Manage reader information and borrowing history
- **BorrowingProvider**: Handle borrowing/returning operations and status updates
- **StatisticsProvider**: Aggregate system-wide statistics for managers

### Provider Types to Use
- **StateProvider**: For simple state like current branch selection
- **StateNotifierProvider**: For complex state like authentication and borrowing operations
- **FutureProvider**: For API calls and async data fetching
- **StreamProvider**: For real-time updates and distributed data synchronization
- **Provider**: For dependency injection and computed values

### Data Layer Architecture
```dart
// Repository Pattern with Riverpod
final apiRepositoryProvider = Provider<ApiRepository>((ref) => ApiRepository());
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());
final bookRepositoryProvider = Provider<BookRepository>((ref) => BookRepository());

// State Notifiers for Complex Logic
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

// Future Providers for API Calls
final branchBooksProvider = FutureProvider.family<List<Book>, String>((ref, branchId) {
  return ref.read(bookRepositoryProvider).getBooksByBranch(branchId);
});
```

### For THUTHU (Librarian) Role:
- Login screen with branch selection
- Book borrowing interface with reader search
- Book return interface with status updates
- Local inventory management
- Branch-specific reporting

### For QUANLY (Manager) Role:
- System-wide dashboard with statistics
- Cross-branch book search interface
- Distributed query results visualization
- System health monitoring
- User management interface

## Key Features

- **Transparency**: Hide distributed system complexity from users
- **Real-time Updates**: Show live borrowing/returning status
- **Search Interface**: Unified search across all library branches
- **Responsive Design**: Adapt to different screen sizes
- **Data Validation**: Client-side validation with server confirmation

## Flutter Best Practices with Riverpod

- Use proper widget composition and reusability with ConsumerWidget
- Implement proper navigation with go_router and Riverpod integration
- Use dependency injection through Riverpod providers
- Create custom themes and consistent styling
- Implement proper loading states and error handling with AsyncValue
- Follow clean architecture principles with data/domain/presentation layers
- Use riverpod_generator for code generation and better type safety
- Follow Flutter naming conventions and project structure
- Implement proper testing with riverpod testing utilities

## Libraries to Use

- **State Management**: flutter_riverpod, riverpod_generator, riverpod_annotation
- **HTTP**: dio with interceptors and retry logic
- **Navigation**: go_router with riverpod integration
- **UI**: material 3, flutter_screenutil for responsive design
- **Local Storage**: shared_preferences or hive with riverpod providers
- **Authentication**: flutter_secure_storage integrated with auth providers
- **Code Generation**: build_runner, json_annotation, freezed
- **Testing**: flutter_test, riverpod_test, mocktail
- **Dev Tools**: riverpod_lint for better code analysis

## Error Handling & Loading States

```dart
// Using AsyncValue for robust state handling
class BookListWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsyncValue = ref.watch(branchBooksProvider('Q1'));
    
    return booksAsyncValue.when(
      data: (books) => BookListView(books: books),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error: error),
    );
  }
}

// State management for complex operations
class BorrowingNotifier extends StateNotifier<AsyncValue<void>> {
  BorrowingNotifier(this._repository) : super(const AsyncValue.data(null));
  
  final BorrowingRepository _repository;
  
  Future<void> borrowBook(String readerId, String bookId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.borrowBook(readerId, bookId));
  }
}
```