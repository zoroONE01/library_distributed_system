import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/api/api_client.dart';
import 'package:library_distributed_app/data/repositories/book_transfer_repository_impl.dart';
import 'package:library_distributed_app/data/services/book_copies_service.dart';
import 'package:library_distributed_app/data/services/books_service.dart';
import 'package:library_distributed_app/data/services/coordinator_service.dart';
import 'package:library_distributed_app/domain/entities/book_transfer.dart';
import 'package:library_distributed_app/domain/repositories/book_transfer_repository.dart';
import 'package:library_distributed_app/domain/usecases/book_transfer_usecase.dart';
import 'package:library_distributed_app/presentation/auth/auth_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'book_transfer_provider.g.dart';

/// Repository provider for book transfer operations
@riverpod
BookTransferRepository bookTransferRepository(Ref ref) {
  final coordinatorService = ref.read(apiClientProvider).getService<CoordinatorService>();
  final bookCopiesService = ref.read(apiClientProvider).getService<BookCopiesService>();
  final booksService = ref.read(apiClientProvider).getService<BooksService>();
  
  return BookTransferRepositoryImpl(
    coordinatorService,
    bookCopiesService,
    booksService,
  );
}

/// Transfer book copy between sites using 2PC protocol
/// Only available for QUANLY (Manager) role
@riverpod
Future<void> transferBookCopy(
  Ref ref,
  BookTransferRequestEntity request,
) async {
  // Check authentication and role
  final isAuthenticated = await ref.watch(authProvider.future);
  if (!isAuthenticated) {
    throw Exception('Authentication required');
  }

  final userInfo = await ref.watch(getUserInfoProvider.future);
  if (userInfo.role.name != 'QUANLY') {
    throw Exception('Only managers can transfer books between sites');
  }

  final useCase = TransferBookCopyUseCase(ref.read(bookTransferRepositoryProvider));
  final result = await useCase.call(request);
  ref.keepAlive();

  result.fold(
    (success) {
      // Invalidate related providers to refresh data
      ref.invalidate(transferableBookCopiesProvider);
    },
    (failure) {
      throw failure;
    },
  );
}

/// Get book copy transfer information for validation
@riverpod
Future<BookCopyTransferInfoEntity> bookCopyTransferInfo(
  Ref ref,
  String bookCopyId,
) async {
  if (bookCopyId.isEmpty) {
    throw Exception('Book copy ID is required');
  }

  final useCase = GetBookCopyTransferInfoUseCase(ref.read(bookTransferRepositoryProvider));
  final result = await useCase.call(bookCopyId);
  ref.keepAlive();

  return result.fold(
    (bookInfo) => bookInfo,
    (failure) => throw failure,
  );
}

/// Search for transferable book copies
/// Results are cached and refreshed when needed
@riverpod
class TransferableBookCopies extends _$TransferableBookCopies {
  @override
  Future<List<BookCopyTransferInfoEntity>> build() async {
    // Check authentication first
    final isAuthenticated = await ref.watch(authProvider.future);
    if (!isAuthenticated) {
      throw Exception('Authentication required');
    }

    // Return empty list initially
    return [];
  }

  /// Search for transferable book copies
  Future<void> search(String searchQuery) async {
    if (searchQuery.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      state = const AsyncValue.loading();

      final useCase = SearchTransferableBookCopiesUseCase(
        ref.read(bookTransferRepositoryProvider),
      );
      final result = await useCase.call(searchQuery.trim());

      result.fold(
        (bookCopies) {
          state = AsyncValue.data(bookCopies);
        },
        (failure) {
          state = AsyncValue.error(failure, StackTrace.current);
        },
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Clear search results
  void clear() {
    state = const AsyncValue.data([]);
  }
}

/// Current search query for transferable book copies
final transferableBookCopiesSearchProvider = StateProvider<String>((ref) => '');

/// Validation provider for book transfer requests
@riverpod
Future<bool> validateBookTransferRequest(
  Ref ref,
  BookTransferRequestEntity request,
) async {
  try {
    // Basic validation
    if (!request.isValid) {
      return false;
    }

    // Check if book copy exists and is available
    final bookInfo = await ref.watch(
      bookCopyTransferInfoProvider(request.bookCopyId).future,
    );

    // Verify book is at source site
    if (bookInfo.currentSite != request.fromSite) {
      return false;
    }

    // Verify book is available for transfer
    return bookInfo.isAvailableForTransfer;
  } catch (e) {
    return false;
  }
}
