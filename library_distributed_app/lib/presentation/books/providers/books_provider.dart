import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/domain/entities/book.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:library_distributed_app/domain/repositories/books_repository.dart';
import 'package:library_distributed_app/domain/usecases/books_usecase.dart';
import 'package:library_distributed_app/presentation/auth/auth_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'books_provider.g.dart';

/// Main provider for books state management
/// Implements role-based access control for FR7 and FR10 requirements
@riverpod
class Books extends _$Books {
  @override
  Future<BooksEntity> build() async {
    // Check authentication first
    final isAuthenticated = await ref.watch(authProvider.future);
    if (!isAuthenticated) {
      throw Exception('Authentication required');
    }

    // Fetch initial data directly and return result
    return await _fetchDataDirect();
  }

  /// Fetch books with availability and return result directly (for build method)
  Future<BooksEntity> _fetchDataDirect([int page = 0, String? search]) async {
    try {
      if (search != null && search.isNotEmpty) {
        // Use system-wide search when search term is provided (FR7)
        final searchUseCase = SearchBooksSystemWideUseCase(
          ref.read(booksRepositoryProvider),
        );
        final result = await searchUseCase.call(search);

        return result.fold(
          (searchResults) {
            // Convert search results to books for display
            final books = searchResults.map((result) => result.book).toList();
            return BooksEntity(
              items: books,
              paging: const PagingEntity(
                currentPage: 0,
                totalPages: 1,
                pageSize: 50,
              ),
            );
          },
          (failure) {
            throw failure;
          },
        );
      } else {
        // Use normal books with availability fetch
        final useCase = GetBooksWithAvailabilityUseCase(
          ref.read(booksRepositoryProvider),
        );
        final result = await useCase.call(page);

        return result.fold(
          (success) {
            final (booksWithAvailability, paging) = success;
            // Convert books with availability to regular books for now
            final books = booksWithAvailability
                .map(
                  (bookWithAvailability) => BookEntity(
                    isbn: bookWithAvailability.isbn,
                    title: bookWithAvailability.title,
                    author: bookWithAvailability.author,
                  ),
                )
                .toList();
            return BooksEntity(items: books, paging: paging);
          },
          (failure) {
            throw failure;
          },
        );
      }
    } catch (e) {
      throw Exception('Error getting books: $e');
    }
  }

  /// Fetch books with pagination and search
  /// FR7: System-wide search when search term provided
  /// Regular availability view when no search
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
    final currentSearch = ref.read(booksSearchProvider);
    await fetchData(currentPage, currentSearch.isEmpty ? null : currentSearch);
  }
}

/// Search state provider for books
final booksSearchProvider = StateProvider<String>((ref) => '');

/// Get books with availability information (enhanced for distributed system)
@riverpod
Future<(List<BookWithAvailabilityEntity>, PagingEntity)> booksWithAvailability(
  Ref ref,
  int page,
) async {
  final useCase = GetBooksWithAvailabilityUseCase(
    ref.read(booksRepositoryProvider),
  );
  final result = await useCase.call(page);
  ref.keepAlive();

  return result.fold((success) => success, (failure) => throw failure);
}

/// Get book by ISBN
@riverpod
Future<BookEntity> bookByIsbn(Ref ref, String isbn) async {
  final useCase = GetBookByIsbnUseCase(ref.read(booksRepositoryProvider));
  final result = await useCase.call(isbn);
  ref.keepAlive();

  return result.fold((book) => book, (failure) => throw failure);
}

/// Get available book copy by ISBN
@riverpod
Future<BookEntity> availableBookCopy(Ref ref, String isbn) async {
  final useCase = GetAvailableBookCopyUseCase(
    ref.read(booksRepositoryProvider),
  );
  final result = await useCase.call(isbn);
  ref.keepAlive();

  return result.fold((book) => book, (failure) => throw failure);
}

/// FR7: Search books system-wide (distributed query)
@riverpod
Future<List<BookSearchResultEntity>> searchBooksSystemWide(
  Ref ref,
  String bookTitle,
) async {
  final useCase = SearchBooksSystemWideUseCase(
    ref.read(booksRepositoryProvider),
  );
  final result = await useCase.call(bookTitle);
  ref.keepAlive();

  return result.fold(
    (searchResults) => searchResults,
    (failure) => throw failure,
  );
}

/// FR10: Create new book in catalog (QUANLY only, uses 2PC)
@riverpod
Future<void> createBook(Ref ref, BookEntity book) async {
  final useCase = CreateBookUseCase(ref.read(booksRepositoryProvider));
  final result = await useCase.call(book);
  ref.keepAlive();

  result.fold(
    (success) {
      ref.invalidate(booksProvider);
    },
    (failure) {
      throw failure;
    },
  );
}

/// FR10: Update book in catalog (QUANLY only, uses 2PC)
@riverpod
Future<void> updateBook(
  Ref ref,
  ({String isbn, BookEntity book}) params,
) async {
  final useCase = UpdateBookUseCase(ref.read(booksRepositoryProvider));
  final result = await useCase.call(params);
  ref.keepAlive();

  result.fold(
    (success) {
      ref.invalidate(booksProvider);
    },
    (failure) {
      throw failure;
    },
  );
}

/// FR10: Delete book from catalog (QUANLY only, uses 2PC)
@riverpod
Future<void> deleteBook(Ref ref, String isbn) async {
  final useCase = DeleteBookUseCase(ref.read(booksRepositoryProvider));
  final result = await useCase.call(isbn);
  ref.keepAlive();

  result.fold(
    (success) {
      ref.invalidate(booksProvider);
    },
    (failure) {
      throw failure;
    },
  );
}
