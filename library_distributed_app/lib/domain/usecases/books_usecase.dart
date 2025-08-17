import 'dart:async';

import 'package:library_distributed_app/domain/entities/book.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:library_distributed_app/domain/repositories/books_repository.dart';
import 'package:library_distributed_app/domain/usecases/usecases.dart';
import 'package:result_dart/result_dart.dart';

// Using Dart record types for parameters
typedef UpdateBookParams = ({String isbn, BookEntity book});

// FR7, FR10: Enhanced Books Use Cases
// ===================================

/// Get books with availability information (enhanced for distributed system)
class GetBooksWithAvailabilityUseCase
    extends
        UseCaseWithParams<
          (List<BookWithAvailabilityEntity>, PagingEntity),
          int
        > {
  const GetBooksWithAvailabilityUseCase(this._repository);
  final BooksRepository _repository;

  @override
  Future<Result<(List<BookWithAvailabilityEntity>, PagingEntity)>> call(
    int page,
  ) {
    return _repository.getBooksWithAvailability(page: page);
  }
}

/// Get book by ISBN
class GetBookByIsbnUseCase extends UseCaseWithParams<BookEntity, String> {
  const GetBookByIsbnUseCase(this._repository);
  final BooksRepository _repository;

  @override
  Future<Result<BookEntity>> call(String isbn) {
    if (isbn.isEmpty) {
      return Future.value(Failure(Exception('ISBN cannot be empty')));
    }
    return _repository.getBookByIsbn(isbn);
  }
}

/// Get available book copy by ISBN
class GetAvailableBookCopyUseCase
    extends UseCaseWithParams<BookEntity, String> {
  const GetAvailableBookCopyUseCase(this._repository);
  final BooksRepository _repository;

  @override
  Future<Result<BookEntity>> call(String isbn) {
    if (isbn.isEmpty) {
      return Future.value(Failure(Exception('ISBN cannot be empty')));
    }
    return _repository.getAvailableBookCopy(isbn);
  }
}

/// FR7: Search books system-wide (distributed query)
/// This implements the requirement for managers and readers to search books across all sites
class SearchBooksSystemWideUseCase
    extends UseCaseWithParams<List<BookSearchResultEntity>, String> {
  const SearchBooksSystemWideUseCase(this._repository);
  final BooksRepository _repository;

  @override
  Future<Result<List<BookSearchResultEntity>>> call(String bookTitle) {
    if (bookTitle.isEmpty) {
      return Future.value(Failure(Exception('Book title cannot be empty')));
    }

    // Trim and validate search term
    final trimmedTitle = bookTitle.trim();
    if (trimmedTitle.length < 2) {
      return Future.value(
        Failure(Exception('Search term must be at least 2 characters')),
      );
    }

    return _repository.searchBooksSystemWide(trimmedTitle);
  }
}

/// FR10: Create new book in catalog (QUANLY only, uses 2PC)
class CreateBookUseCase extends UseCaseWithParams<BookEntity, BookEntity> {
  const CreateBookUseCase(this._repository);
  final BooksRepository _repository;

  @override
  Future<Result<BookEntity>> call(BookEntity book) async {
    // Validate book data
    if (book.isbn.isEmpty) {
      return Failure(Exception('ISBN cannot be empty'));
    }
    if (book.title.isEmpty) {
      return Failure(Exception('Book title cannot be empty'));
    }
    if (book.author.isEmpty) {
      return Failure(Exception('Book author cannot be empty'));
    }

    return _repository.createBook(book);
  }
}

/// FR10: Update book in catalog (QUANLY only, uses 2PC)
class UpdateBookUseCase
    extends UseCaseWithParams<BookEntity, UpdateBookParams> {
  const UpdateBookUseCase(this._repository);
  final BooksRepository _repository;

  @override
  Future<Result<BookEntity>> call(UpdateBookParams params) async {
    // Validate parameters
    if (params.isbn.isEmpty) {
      return Failure(Exception('ISBN cannot be empty'));
    }
    if (params.book.title.isEmpty) {
      return Failure(Exception('Book title cannot be empty'));
    }
    if (params.book.author.isEmpty) {
      return Failure(Exception('Book author cannot be empty'));
    }

    return _repository.updateBook(params.isbn, params.book);
  }
}

/// FR10: Delete book from catalog (QUANLY only, uses 2PC)
class DeleteBookUseCase extends VoidUseCaseWithParams<String> {
  const DeleteBookUseCase(this._repository);
  final BooksRepository _repository;

  @override
  Future<Result<String>> call(String isbn) async {
    if (isbn.isEmpty) {
      return failure('ISBN cannot be empty');
    }

    final result = await _repository.deleteBook(isbn);
    return result.fold(
      (success) => this.success,
      (failure) => this.failure(failure),
    );
  }
}
