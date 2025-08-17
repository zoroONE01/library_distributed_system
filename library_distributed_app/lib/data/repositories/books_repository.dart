import 'package:library_distributed_app/data/services/books_service.dart';
import 'package:library_distributed_app/data/services/manager_service.dart';
import 'package:library_distributed_app/data/models/book.dart';
import 'package:library_distributed_app/data/models/book_with_availability.dart';
import 'package:library_distributed_app/data/models/book_search_result.dart';
import 'package:library_distributed_app/domain/entities/book.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:library_distributed_app/domain/repositories/books_repository.dart';
import 'package:result_dart/result_dart.dart';

class BookRepositoryImpl implements BooksRepository {
  final BooksService _service;
  final ManagerService _managerService;

  const BookRepositoryImpl(this._service, this._managerService);

  @override
  Future<Result<(List<BookWithAvailabilityEntity>, PagingEntity)>> getBooksWithAvailability({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'size': size.toString(),
      };

      final response = await _service.getList(params);
      
      if (response.isSuccessful && response.body != null) {
        final listResponse = response.body!;
        
        final books = listResponse.items
            .map((model) => _mapBookWithAvailabilityModelToEntity(model))
            .toList();
        
        final paging = PagingEntity(
          currentPage: listResponse.paging.page,
          pageSize: listResponse.paging.size,
          totalPages: listResponse.paging.totalPages ?? 1,
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
  Future<Result<List<BookSearchResultEntity>>> searchBooksSystemWide(String bookTitle) async {
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

  // Legacy methods implementation
  @override
  Future<Result<BooksEntity>> getList(PagingEntity paging) async {
    try {
      final result = await getBooksWithAvailability(
        page: paging.currentPage,
        size: paging.pageSize,
      );
      
      return result.fold(
        (success) {
          final (books, pagingInfo) = success;
          final bookEntities = books.map((book) => BookEntity(
            isbn: book.isbn,
            title: book.title,
            author: book.author,
          )).toList();
          
          return Success(BooksEntity(
            items: bookEntities,
            paging: pagingInfo,
          ));
        },
        (failure) => Failure(failure),
      );
    } catch (e) {
      return Failure(Exception('Error in legacy getList: $e'));
    }
  }

  @override
  Future<Result<BookEntity>> get(String id) async {
    return await getBookByIsbn(id);
  }

  @override
  Future<Result<String>> createNew(BookEntity book) async {
    final result = await createBook(book);
    return result.fold(
      (success) => Success(success.isbn),
      (failure) => Failure(failure),
    );
  }

  @override
  Future<Result<String>> update(BookEntity book) async {
    final result = await updateBook(book.isbn, book);
    return result.fold(
      (success) => Success(success.isbn),
      (failure) => Failure(failure),
    );
  }

  @override
  Future<Result<String>> delete(String id) async {
    final result = await deleteBook(id);
    return result.fold(
      (success) => Success(id),
      (failure) => Failure(failure),
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

  BookWithAvailabilityEntity _mapBookWithAvailabilityModelToEntity(BookWithAvailabilityModel model) {
    return BookWithAvailabilityEntity(
      isbn: model.isbn,
      title: model.title,
      author: model.author,
      availableCount: model.availableCount,
      totalCount: model.totalCount,
      borrowedCount: model.borrowedCount,
    );
  }

  BookSearchResultEntity _mapBookSearchResultModelToEntity(BookSearchResultModel model) {
    return BookSearchResultEntity(
      book: _mapBookModelToEntity(model.book),
      availableBranches: [], // This would need proper mapping based on model structure
      availableCount: model.availableCount,
    );
  }
}
