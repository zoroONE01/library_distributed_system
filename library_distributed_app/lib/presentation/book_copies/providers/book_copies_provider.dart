import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/domain/entities/book_copy.dart';
import 'package:library_distributed_app/domain/repositories/book_copies_repository.dart';
import 'package:library_distributed_app/domain/usecases/book_copies_usecase.dart';
import 'package:library_distributed_app/presentation/auth/auth_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'book_copies_provider.g.dart';

/// Main provider for book copies state management
/// Implements role-based access control as per FR9 requirements
@riverpod
class BookCopies extends _$BookCopies {
  @override
  Future<BookCopiesEntity> build() async {
    // Check authentication first
    final isAuthenticated = await ref.watch(authProvider.future);
    if (!isAuthenticated) {
      throw Exception('Authentication required');
    }

    // Fetch initial data directly and return result
    return await _fetchDataDirect();
  }

  /// Fetch book copies and return result directly (for build method)
  Future<BookCopiesEntity> _fetchDataDirect([
    int page = 0,
    String? search,
  ]) async {
    try {
      final useCase = GetBookCopiesUseCase(
        ref.read(bookCopiesRepositoryProvider),
      );
      final result = await useCase.call((page: page, search: search));

      return result.fold(
        (success) {
          final (bookCopies, paging) = success;
          return BookCopiesEntity(items: bookCopies, paging: paging);
        },
        (failure) {
          throw failure;
        },
      );
    } catch (e) {
      throw Exception('Error getting book copies: $e');
    }
  }

  /// Fetch book copies with pagination and search
  /// FR9: THUTHU sees only their site, QUANLY sees system-wide
  Future<void> fetchData([int page = 0, String? search]) async {
    try {
      state = const AsyncValue.loading();

      final result = await _fetchDataDirect(page, search);
      state = AsyncValue.data(result);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    final currentState = state.valueOrNull;
    final currentPage = currentState?.paging.currentPage ?? 0;
    await fetchData(currentPage);
  }
}

/// Search state provider for book copies
final bookCopiesSearchProvider = StateProvider<String>((ref) => '');

/// Create new book copy - FR9: THUTHU only at their site
@riverpod
Future<void> createBookCopy(Ref ref, BookCopyEntity bookCopy) async {
  final useCase = CreateBookCopyUseCase(ref.read(bookCopiesRepositoryProvider));
  final result = await useCase.call(bookCopy);
  ref.keepAlive();

  result.fold(
    (success) {
      ref.invalidate(bookCopiesProvider);
    },
    (failure) {
      throw failure;
    },
  );
}

/// Update book copy - FR9: THUTHU only at their site
@riverpod
Future<void> updateBookCopy(
  Ref ref,
  ({String bookCopyId, BookCopyEntity bookCopy}) params,
) async {
  final useCase = UpdateBookCopyUseCase(ref.read(bookCopiesRepositoryProvider));
  final result = await useCase.call((
    bookCopyId: params.bookCopyId,
    bookCopy: params.bookCopy,
  ));
  ref.keepAlive();

  result.fold(
    (success) {
      ref.invalidate(bookCopiesProvider);
    },
    (failure) {
      throw failure;
    },
  );
}

/// Delete book copy - FR9: THUTHU only at their site
/// Only allowed if book copy is not currently borrowed
@riverpod
Future<void> deleteBookCopy(Ref ref, String bookCopyId) async {
  final useCase = DeleteBookCopyUseCase(ref.read(bookCopiesRepositoryProvider));
  final result = await useCase.call(bookCopyId);
  ref.keepAlive();

  result.fold(
    (success) {
      ref.invalidate(bookCopiesProvider);
    },
    (failure) {
      throw failure;
    },
  );
}

/// Check if book copy is available for operations
@riverpod
Future<bool> isBookCopyAvailable(Ref ref, String bookCopyId) async {
  final useCase = IsBookCopyAvailableUseCase(
    ref.read(bookCopiesRepositoryProvider),
  );
  final result = await useCase.call(bookCopyId);
  ref.keepAlive();

  return result.fold(
    (isAvailable) => isAvailable,
    (failure) => false, // If we can't check, assume not available for safety
  );
}

/// Get single book copy by ID
@riverpod
Future<BookCopyEntity> bookCopyById(Ref ref, String bookCopyId) async {
  final useCase = GetBookCopyByIdUseCase(
    ref.read(bookCopiesRepositoryProvider),
  );
  final result = await useCase.call(bookCopyId);
  ref.keepAlive();

  return result.fold((bookCopy) => bookCopy, (failure) => throw failure);
}
