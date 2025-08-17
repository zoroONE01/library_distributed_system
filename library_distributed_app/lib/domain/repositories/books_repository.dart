import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/api/api_client.dart';
import 'package:library_distributed_app/data/repositories/books_repository.dart';
import 'package:library_distributed_app/data/services/books_service.dart';
import 'package:library_distributed_app/data/services/manager_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:library_distributed_app/domain/entities/book.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:result_dart/result_dart.dart';

part 'books_repository.g.dart';

/// Repository interface for Books operations (FR7, FR10)
/// - FR7: Tìm kiếm sách toàn hệ thống (distributed query)
/// - FR10: CRUD đầu sách toàn hệ thống với 2PC (QUANLY only)
abstract class BooksRepository {
  /// Get books with availability information (enhanced for distributed system)
  Future<Result<(List<BookWithAvailabilityEntity>, PagingEntity)>>
  getBooksWithAvailability({int page = 0, int size = 20});

  /// Get book by ISBN
  Future<Result<BookEntity>> getBookByIsbn(String isbn);

  /// Get available book copy by ISBN
  Future<Result<BookEntity>> getAvailableBookCopy(String isbn);

  /// Search books system-wide (FR7 - distributed query)
  Future<Result<List<BookSearchResultEntity>>> searchBooksSystemWide(
    String bookTitle,
  );

  /// Create new book in catalog (FR10 - QUANLY only, uses 2PC)
  Future<Result<BookEntity>> createBook(BookEntity book);

  /// Update book in catalog (FR10 - QUANLY only, uses 2PC)
  Future<Result<BookEntity>> updateBook(String isbn, BookEntity book);

  /// Delete book from catalog (FR10 - QUANLY only, uses 2PC)
  Future<Result<void>> deleteBook(String isbn);

  /// Legacy methods for backward compatibility
  @Deprecated('Use getBooksWithAvailability instead')
  Future<Result<BooksEntity>> getList(PagingEntity paging);

  @Deprecated('Use getBookByIsbn instead')
  Future<Result<BookEntity>> get(String id);

  @Deprecated('Use createBook instead')
  Future<Result<String>> createNew(BookEntity book);

  @Deprecated('Use updateBook instead')
  Future<Result<String>> update(BookEntity book);

  @Deprecated('Use deleteBook instead')
  Future<Result<String>> delete(String id);
}

@riverpod
BooksRepository booksRepository(Ref ref) {
  final bookService = ref.read(apiClientProvider).getService<BooksService>();
  final managerService = ref
      .read(apiClientProvider)
      .getService<ManagerService>();
  return BookRepositoryImpl(bookService, managerService);
}
