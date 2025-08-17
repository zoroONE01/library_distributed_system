import 'dart:async';

import 'package:library_distributed_app/domain/entities/borrow_record.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:library_distributed_app/domain/repositories/borrow_repository.dart';
import 'package:library_distributed_app/domain/usecases/usecases.dart';
import 'package:result_dart/result_dart.dart';

// Using Dart record types for parameters
typedef GetBorrowRecordsParams = ({int page, String? search});
typedef GetBorrowRecordsWithDetailsParams = ({int page, String? search});

// FR2, FR3, FR4: Borrowing Use Cases
// ==================================

/// FR4: Get borrow records with pagination (local queries for THUTHU)
class GetBorrowRecordsUseCase
    extends
        UseCaseWithParams<
          (List<BorrowRecordEntity>, PagingEntity),
          GetBorrowRecordsParams
        > {
  const GetBorrowRecordsUseCase(this._repository);
  final BorrowRepository _repository;

  @override
  Future<Result<(List<BorrowRecordEntity>, PagingEntity)>> call(
    GetBorrowRecordsParams params,
  ) {
    return _repository.getBorrowRecords(
      page: params.page,
      search: params.search,
    );
  }
}

/// Enhanced borrow records with detailed information (for Flutter app)
class GetBorrowRecordsWithDetailsUseCase
    extends
        UseCaseWithParams<
          (List<BorrowRecordWithDetailsEntity>, PagingEntity),
          GetBorrowRecordsWithDetailsParams
        > {
  const GetBorrowRecordsWithDetailsUseCase(this._repository);
  final BorrowRepository _repository;

  @override
  Future<Result<(List<BorrowRecordWithDetailsEntity>, PagingEntity)>> call(
    GetBorrowRecordsWithDetailsParams params,
  ) {
    return _repository.getBorrowRecordsWithDetails(
      page: params.page,
      search: params.search,
    );
  }
}

/// Get borrow record by ID
class GetBorrowRecordByIdUseCase
    extends UseCaseWithParams<BorrowRecordEntity, int> {
  const GetBorrowRecordByIdUseCase(this._repository);
  final BorrowRepository _repository;

  @override
  Future<Result<BorrowRecordEntity>> call(int borrowId) {
    if (borrowId <= 0) {
      return Future.value(Failure(Exception('Invalid borrow ID')));
    }
    return _repository.getBorrowRecordById(borrowId);
  }
}

/// FR2: Create borrow record (lập phiếu mượn sách)
/// Implements business logic for book borrowing process
class CreateBorrowRecordUseCase
    extends UseCaseWithParams<BorrowRecordEntity, CreateBorrowRequestEntity> {
  const CreateBorrowRecordUseCase(this._repository);
  final BorrowRepository _repository;

  @override
  Future<Result<BorrowRecordEntity>> call(
    CreateBorrowRequestEntity request,
  ) async {
    // Validate request data
    if (request.readerId.isEmpty) {
      return Failure(Exception('Reader ID cannot be empty'));
    }
    if (request.bookCopyId.isEmpty) {
      return Failure(Exception('Book copy ID cannot be empty'));
    }

    return _repository.createBorrow(request);
  }
}

/// FR3: Return book (ghi nhận trả sách)
/// Updates borrow record with return date and makes book available
class ReturnBookUseCase
    extends VoidUseCaseWithParams<({int borrowId, String? bookCopyId})> {
  const ReturnBookUseCase(this._repository);
  final BorrowRepository _repository;

  @override
  Future<Result<String>> call(
    ({int borrowId, String? bookCopyId}) params,
  ) async {
    if (params.borrowId <= 0) {
      return failure('Invalid borrow ID');
    }

    final result = await _repository.returnBook(
      params.borrowId,
      params.bookCopyId,
    );
    return result.fold(
      (success) => this.success,
      (failure) => this.failure(failure),
    );
  }
}

/// Check if reader has active borrows (for business rule validation)
class HasActiveReaderBorrowsUseCase extends UseCaseWithParams<bool, String> {
  const HasActiveReaderBorrowsUseCase(this._repository);
  final BorrowRepository _repository;

  @override
  Future<Result<bool>> call(String readerId) {
    if (readerId.isEmpty) {
      return Future.value(Failure(Exception('Reader ID cannot be empty')));
    }
    return _repository.hasActiveBorrows(readerId);
  }
}

/// Check if book copy is currently borrowed (for deletion validation)
class IsBookCopyBorrowedUseCase extends UseCaseWithParams<bool, String> {
  const IsBookCopyBorrowedUseCase(this._repository);
  final BorrowRepository _repository;

  @override
  Future<Result<bool>> call(String bookCopyId) {
    if (bookCopyId.isEmpty) {
      return Future.value(Failure(Exception('Book copy ID cannot be empty')));
    }
    return _repository.isBookCopyBorrowed(bookCopyId);
  }
}
