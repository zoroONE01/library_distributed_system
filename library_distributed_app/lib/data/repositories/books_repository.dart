import 'package:library_distributed_app/core/constants/common.dart';
import 'package:library_distributed_app/core/constants/enums.dart';
import 'package:library_distributed_app/data/models/book.dart';
import 'package:library_distributed_app/data/models/book_search_result.dart';
import 'package:library_distributed_app/data/services/books_service.dart';
import 'package:library_distributed_app/data/services/manager_service.dart';
import 'package:library_distributed_app/domain/entities/book.dart';
import 'package:library_distributed_app/domain/entities/branch.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:library_distributed_app/domain/repositories/books_repository.dart';
import 'package:result_dart/result_dart.dart';

class BookRepositoryImpl implements BooksRepository {
  final BooksService _service;
  final ManagerService _managerService;

  const BookRepositoryImpl(this._service, this._managerService);

  @override
  Future<Result<(List<BookWithAvailabilityEntity>, PagingEntity)>>
  getBooksWithAvailability({int page = 0}) async {
    try {
      final params = {
        'page': page.toString(),
        'size': kPaginationPageSize.toString(),
      };

      final response = await _service.getList(params);

      if (response.isSuccessful && response.body != null) {
        final booksModel = response.body!;

        // Convert BookModel to BookWithAvailabilityEntity
        // Since server only returns basic book info, we set availability counts to 0
        final books = booksModel.items
            .map((model) => BookWithAvailabilityEntity(
                  isbn: model.isbn,
                  title: model.title,
                  author: model.author,
                  availableCount: 0, // Server doesn't provide this in /books endpoint
                  totalCount: 0,     // Server doesn't provide this in /books endpoint
                  borrowedCount: 0,  // Server doesn't provide this in /books endpoint
                ))
            .toList();

        final paging = PagingEntity(
          currentPage: booksModel.paging.page,
          pageSize: booksModel.paging.size,
          totalPages: booksModel.paging.totalPages ?? 1,
        );

        return Success((books, paging));
      }

      return Failure(Exception('Failed to get books: ${response.error}'));
    } catch (e) {
      return Failure(Exception('Error getting books: $e'));
    }
  }

  @override
  Future<Result<BookEntity>> getBookByIsbn(String isbn) async {
    try {
      final response = await _service.get(isbn);

      if (response.isSuccessful && response.body != null) {
        return Success(_mapBookModelToEntity(response.body!));
      }

      return Failure(Exception('Book not found'));
    } catch (e) {
      return Failure(Exception('Error getting book by ISBN: $e'));
    }
  }

  @override
  Future<Result<BookEntity>> getAvailableBookCopy(String isbn) async {
    try {
      final response = await _service.getAvailableCopy(isbn);

      if (response.isSuccessful && response.body != null) {
        return Success(_mapBookModelToEntity(response.body!));
      }

      return Failure(Exception('No available book copy found'));
    } catch (e) {
      return Failure(Exception('Error getting available book copy: $e'));
    }
  }

  @override
  Future<Result<List<BookSearchResultEntity>>> searchBooksSystemWide(
    String bookTitle,
  ) async {
    try {
      final response = await _managerService.searchAvailableBooks(bookTitle);

      if (response.isSuccessful && response.body != null) {
        final results = response.body!
            .map((model) => _mapBookSearchResultModelToEntity(model))
            .toList();

        return Success(results);
      }

      return Failure(Exception('Failed to search books: ${response.error}'));
    } catch (e) {
      return Failure(Exception('Error searching books system-wide: $e'));
    }
  }

  @override
  Future<Result<BookEntity>> createBook(BookEntity book) async {
    try {
      final model = _mapBookEntityToModel(book);
      final response = await _managerService.createBook(model);

      if (response.isSuccessful && response.body != null) {
        return Success(_mapBookModelToEntity(response.body!));
      }

      return Failure(Exception('Failed to create book: ${response.error}'));
    } catch (e) {
      return Failure(Exception('Error creating book: $e'));
    }
  }

  @override
  Future<Result<BookEntity>> updateBook(String isbn, BookEntity book) async {
    // Server API does not support book update operation
    return Failure(
      Exception('Book update operation is not supported by the server API'),
    );
  }

  @override
  Future<Result<void>> deleteBook(String isbn) async {
    // Server API does not support book delete operation
    return Failure(
      Exception('Book delete operation is not supported by the server API'),
    );
  }

  // Helper methods for mapping
  BookEntity _mapBookModelToEntity(BookModel model) {
    return BookEntity(
      isbn: model.isbn,
      title: model.title,
      author: model.author,
    );
  }

  BookModel _mapBookEntityToModel(BookEntity entity) {
    return BookModel(
      isbn: entity.isbn,
      title: entity.title,
      author: entity.author,
    );
  }

  BookSearchResultEntity _mapBookSearchResultModelToEntity(
    BookSearchResultModel model,
  ) {
    return BookSearchResultEntity(
      book: _mapBookModelToEntity(model.book),
      availableBranches: model.availableBranches
          .map(
            (branch) => BranchEntity(
              siteId: Site.fromString(branch.branchCode),
              name: branch.branchName,
              address: branch.address,
            ),
          )
          .toList(),
      availableCount: model.availableCount,
    );
  }
}
