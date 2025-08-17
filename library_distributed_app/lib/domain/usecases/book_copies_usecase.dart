import 'dart:async';

import 'package:library_distributed_app/domain/entities/book_copy.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:library_distributed_app/domain/repositories/book_copies_repository.dart';
import 'package:library_distributed_app/domain/usecases/usecases.dart';
import 'package:result_dart/result_dart.dart';

// Using Dart record types for parameters
typedef GetBookCopiesParams = ({int page, String? search});
typedef UpdateBookCopyParams = ({String bookCopyId, BookCopyEntity bookCopy});

// FR9: Book Copies Use Cases (THUTHU only at their site)
// ======================================================

/// Get book copies with role-based access control
/// THUTHU: only their site, QUANLY: system-wide
class GetBookCopiesUseCase
    extends
        UseCaseWithParams<
          (List<BookCopyEntity>, PagingEntity),
          GetBookCopiesParams
        > {
  const GetBookCopiesUseCase(this._repository);
  final BookCopiesRepository _repository;

  @override
  Future<Result<(List<BookCopyEntity>, PagingEntity)>> call(
    GetBookCopiesParams params,
  ) {
    return _repository.getBookCopies(page: params.page, search: params.search);
  }
}

/// Get book copy by ID
class GetBookCopyByIdUseCase extends UseCaseWithParams<BookCopyEntity, String> {
  const GetBookCopyByIdUseCase(this._repository);
  final BookCopiesRepository _repository;

  @override
  Future<Result<BookCopyEntity>> call(String bookCopyId) {
    if (bookCopyId.isEmpty) {
      return Future.value(Failure(Exception('Book copy ID cannot be empty')));
    }
    return _repository.getBookCopyById(bookCopyId);
  }
}

/// Create new book copy (FR9 - THUTHU only at their site)
class CreateBookCopyUseCase
    extends UseCaseWithParams<BookCopyEntity, BookCopyEntity> {
  const CreateBookCopyUseCase(this._repository);
  final BookCopiesRepository _repository;

  @override
  Future<Result<BookCopyEntity>> call(BookCopyEntity bookCopy) async {
    // Validate book copy data
    if (bookCopy.bookCopyId.isEmpty) {
      return Failure(Exception('Book copy ID cannot be empty'));
    }
    if (bookCopy.isbn.isEmpty) {
      return Failure(Exception('ISBN cannot be empty'));
    }

    return _repository.createBookCopy(bookCopy);
  }
}

/// Update book copy (FR9 - THUTHU only at their site)
class UpdateBookCopyUseCase
    extends UseCaseWithParams<BookCopyEntity, UpdateBookCopyParams> {
  const UpdateBookCopyUseCase(this._repository);
  final BookCopiesRepository _repository;

  @override
  Future<Result<BookCopyEntity>> call(UpdateBookCopyParams params) async {
    // Validate parameters
    if (params.bookCopyId.isEmpty) {
      return Failure(Exception('Book copy ID cannot be empty'));
    }
    if (params.bookCopy.isbn.isEmpty) {
      return Failure(Exception('ISBN cannot be empty'));
    }

    return _repository.updateBookCopy(params.bookCopyId, params.bookCopy);
  }
}

/// Delete book copy (FR9 - THUTHU only at their site)
/// Only allowed if book copy is not currently borrowed
class DeleteBookCopyUseCase extends VoidUseCaseWithParams<String> {
  const DeleteBookCopyUseCase(this._repository);
  final BookCopiesRepository _repository;

  @override
  Future<Result<String>> call(String bookCopyId) async {
    if (bookCopyId.isEmpty) {
      return failure('Book copy ID cannot be empty');
    }

    // Check if book copy is available for deletion (business rule)
    final availabilityResult = await _repository.isBookCopyAvailable(
      bookCopyId,
    );
    final isAvailable = availabilityResult.fold(
      (available) => available,
      (error) => false, // If we can't check, assume not available for safety
    );

    if (!isAvailable) {
      return failure(
        'Cannot delete book copy: it may be currently borrowed or not found',
      );
    }

    final result = await _repository.deleteBookCopy(bookCopyId);
    return result.fold(
      (success) => this.success,
      (failure) => this.failure(failure),
    );
  }
}

/// Check if book copy is available for borrowing
class IsBookCopyAvailableUseCase extends UseCaseWithParams<bool, String> {
  const IsBookCopyAvailableUseCase(this._repository);
  final BookCopiesRepository _repository;

  @override
  Future<Result<bool>> call(String bookCopyId) {
    if (bookCopyId.isEmpty) {
      return Future.value(Failure(Exception('Book copy ID cannot be empty')));
    }
    return _repository.isBookCopyAvailable(bookCopyId);
  }
}
