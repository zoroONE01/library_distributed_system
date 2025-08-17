import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/api/api_client.dart';
import 'package:library_distributed_app/data/repositories/book_copies_repository.dart';
import 'package:library_distributed_app/data/services/book_copies_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:library_distributed_app/domain/entities/book_copy.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:result_dart/result_dart.dart';

part 'book_copies_repository.g.dart';

/// Repository interface for Book Copies operations (FR9)
/// - FR9: CRUD quyển sách (THUTHU only at their site)
abstract class BookCopiesRepository {
  /// Get book copies with role-based access control
  /// THUTHU: only their site, QUANLY: system-wide
  Future<Result<(List<BookCopyEntity>, PagingEntity)>> getBookCopies({
    int page = 0,
    int size = 20,
    String? search,
  });

  /// Get book copy by ID
  Future<Result<BookCopyEntity>> getBookCopyById(String bookCopyId);

  /// Create new book copy (FR9 - THUTHU only at their site)
  Future<Result<BookCopyEntity>> createBookCopy(BookCopyEntity bookCopy);

  /// Update book copy (FR9 - THUTHU only at their site)
  Future<Result<BookCopyEntity>> updateBookCopy(
    String bookCopyId,
    BookCopyEntity bookCopy,
  );

  /// Delete book copy (FR9 - THUTHU only at their site)
  Future<Result<void>> deleteBookCopy(String bookCopyId);

  /// Check if book copy exists and is available for borrowing
  Future<Result<bool>> isBookCopyAvailable(String bookCopyId);

  /// Legacy methods for backward compatibility
  @Deprecated('Use getBookCopies instead')
  Future<Result<BookCopiesEntity>> getList(PagingEntity paging);

  @Deprecated('Use getBookCopyById instead')
  Future<Result<BookCopyEntity>> get(String id);

  @Deprecated('Use createBookCopy instead')
  Future<Result<String>> createNew(BookCopyEntity book);

  @Deprecated('Use updateBookCopy instead')
  Future<Result<String>> update(BookCopyEntity book);

  @Deprecated('Use deleteBookCopy instead')
  Future<Result<String>> delete(String id);
}

@riverpod
BookCopiesRepository bookCopiesRepository(Ref ref) {
  final bookCopiesService = ref
      .read(apiClientProvider)
      .getService<BookCopiesService>();
  return BookCopiesRepositoryImpl(bookCopiesService);
}
