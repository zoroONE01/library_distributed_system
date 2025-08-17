import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/domain/entities/borrow_record.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:library_distributed_app/domain/repositories/borrow_repository.dart';
import 'package:library_distributed_app/domain/usecases/borrowing_usecase.dart';
import 'package:library_distributed_app/presentation/auth/auth_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'borrowing_provider.g.dart';

/// Main provider for borrowing state management
/// Implements FR2 and FR3 requirements for book borrowing and returning
@riverpod
class BorrowRecords extends _$BorrowRecords {
  @override
  Future<BorrowRecordsEntity> build() async {
    // Check authentication first
    final isAuthenticated = await ref.watch(authProvider.future);
    if (!isAuthenticated) {
      throw Exception('Authentication required');
    }

    // Fetch initial data directly and return result
    final result = await _fetchDataDirect();
    
    // Initialize pagination state on first load
    final totalItems = result.paging.totalPages * result.paging.pageSize;
    ref.read(borrowRecordsPaginationProvider.notifier).update((state) => 
      state.copyWith(
        currentPage: 0,
        totalItems: totalItems,
        totalPages: result.paging.totalPages > 0 ? result.paging.totalPages : 1,
        itemsPerPage: result.paging.pageSize,
      ),
    );
    
    return result;
  }

  /// Fetch borrow records and return result directly (for build method)
  Future<BorrowRecordsEntity> _fetchDataDirect([int page = 0, String? search]) async {
    try {
      final useCase = GetBorrowRecordsWithDetailsUseCase(ref.read(borrowRepositoryProvider));
      final result = await useCase.call((page: page, search: search));

      return result.fold(
        (success) {
          final (borrowRecords, paging) = success;
          return BorrowRecordsEntity(items: borrowRecords, paging: paging);
        },
        (failure) {
          throw failure;
        },
      );
    } catch (e) {
      throw Exception('Error getting borrow records: $e');
    }
  }

  /// Fetch borrow records with pagination and search
  /// FR4: THUTHU can view local borrow records
  Future<void> fetchData([int page = 0, String? search]) async {
    try {
      state = const AsyncValue.loading();

      final result = await _fetchDataDirect(page, search);
      
      // Update pagination state - calculate totalItems from paging info
      final totalItems = result.paging.totalPages * result.paging.pageSize;
      ref.read(borrowRecordsPaginationProvider.notifier).update((state) => 
        state.copyWith(
          currentPage: page,
          totalItems: totalItems,
          totalPages: result.paging.totalPages > 0 ? result.paging.totalPages : 1,
          itemsPerPage: result.paging.pageSize,
        ),
      );
      
      state = AsyncValue.data(result);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    final currentState = state.valueOrNull;
    final currentPage = currentState?.paging.currentPage ?? 0;
    final currentSearch = ref.read(borrowSearchProvider);
    await fetchData(currentPage, currentSearch.isEmpty ? null : currentSearch);
  }
}

/// Entity to match the pattern used in other providers
class BorrowRecordsEntity {
  final List<BorrowRecordWithDetailsEntity> items;
  final PagingEntity paging;

  const BorrowRecordsEntity({
    this.items = const [],
    this.paging = const PagingEntity(),
  });
}

/// Pagination state for borrow records
class BorrowRecordsPaginationState {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  const BorrowRecordsPaginationState({
    this.currentPage = 0,
    this.totalPages = 1,
    this.totalItems = 0,
    this.itemsPerPage = 20,
  });

  BorrowRecordsPaginationState copyWith({
    int? currentPage,
    int? totalPages,
    int? totalItems,
    int? itemsPerPage,
  }) {
    return BorrowRecordsPaginationState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
    );
  }
}

/// Provider for pagination state
final borrowRecordsPaginationProvider = StateProvider<BorrowRecordsPaginationState>((ref) {
  return const BorrowRecordsPaginationState();
});

/// Search state provider for borrow records
final borrowSearchProvider = StateProvider<String>((ref) => '');

/// Get borrow record by ID
@riverpod
Future<BorrowRecordEntity> borrowRecordById(Ref ref, int borrowId) async {
  final useCase = GetBorrowRecordByIdUseCase(ref.read(borrowRepositoryProvider));
  final result = await useCase.call(borrowId);
  ref.keepAlive();

  return result.fold((record) => record, (failure) => throw failure);
}

/// FR2: Create new borrow record (lập phiếu mượn sách)
@riverpod
Future<void> createBorrowRecord(Ref ref, CreateBorrowRequestEntity request) async {
  final useCase = CreateBorrowRecordUseCase(ref.read(borrowRepositoryProvider));
  final result = await useCase.call(request);
  ref.keepAlive();

  result.fold(
    (success) {
      ref.invalidate(borrowRecordsProvider);
    },
    (failure) {
      throw failure;
    },
  );
}

/// FR3: Return book (ghi nhận trả sách)
@riverpod
Future<void> returnBook(
  Ref ref,
  ({int borrowId, String? bookCopyId}) params,
) async {
  final useCase = ReturnBookUseCase(ref.read(borrowRepositoryProvider));
  final result = await useCase.call(params);
  ref.keepAlive();

  result.fold(
    (success) {
      ref.invalidate(borrowRecordsProvider);
    },
    (failure) {
      throw failure;
    },
  );
}

/// Check if reader has active borrows (for validation)
@riverpod
Future<bool> hasActiveReaderBorrows(Ref ref, String readerId) async {
  final useCase = HasActiveReaderBorrowsUseCase(ref.read(borrowRepositoryProvider));
  final result = await useCase.call(readerId);
  ref.keepAlive();

  return result.fold((hasActive) => hasActive, (failure) => throw failure);
}

/// Check if book copy is currently borrowed (for validation)
@riverpod
Future<bool> isBookCopyBorrowed(Ref ref, String bookCopyId) async {
  final useCase = IsBookCopyBorrowedUseCase(ref.read(borrowRepositoryProvider));
  final result = await useCase.call(bookCopyId);
  ref.keepAlive();

  return result.fold((isBorrowed) => isBorrowed, (failure) => throw failure);
}
