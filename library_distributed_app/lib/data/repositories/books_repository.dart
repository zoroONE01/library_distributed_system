import 'package:library_distributed_app/core/constants/common.dart';
import 'package:library_distributed_app/data/models/book.dart';
import 'package:library_distributed_app/data/models/book_search_result.dart';
import 'package:library_distributed_app/data/models/book_with_availability.dart';
import 'package:library_distributed_app/data/services/books_service.dart';
import 'package:library_distributed_app/data/services/manager_service.dart';
import 'package:library_distributed_app/domain/entities/book.dart';
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

        final books = booksModel.items
            .map((model) => _mapBookWithAvailabilityModelToEntity(model))
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
    try {
      final model = _mapBookEntityToModel(book);
      final response = await _managerService.updateBook(isbn, model);

      if (response.isSuccessful && response.body != null) {
        return Success(_mapBookModelToEntity(response.body!));
      }

      return Failure(Exception('Failed to update book: ${response.error}'));
    } catch (e) {
      return Failure(Exception('Error updating book: $e'));
    }
  }

  @override
  Future<Result<void>> deleteBook(String isbn) async {
    try {
      final response = await _managerService.deleteBook(isbn);

      if (response.isSuccessful) {
        return const Success(unit);
      }

      return Failure(Exception('Failed to delete book: ${response.error}'));
    } catch (e) {
      return Failure(Exception('Error deleting book: $e'));
    }
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

  BookWithAvailabilityEntity _mapBookWithAvailabilityModelToEntity(
    BookWithAvailabilityModel model,
  ) {
    return BookWithAvailabilityEntity(
      isbn: model.isbn,
      title: model.title,
      author: model.author,
      availableCount: model.availableCount,
      totalCount: model.totalCount,
      borrowedCount: model.borrowedCount,
    );
  }

  BookSearchResultEntity _mapBookSearchResultModelToEntity(
    BookSearchResultModel model,
  ) {
    return BookSearchResultEntity(
      book: _mapBookModelToEntity(model.book),
      availableBranches:
          [], // This would need proper mapping based on model structure
      availableCount: model.availableCount,
    );
  }
}
