import 'package:library_distributed_app/core/constants/common.dart';
import 'package:library_distributed_app/data/models/borrow_record.dart';
import 'package:library_distributed_app/data/models/borrow_record_with_details.dart';
import 'package:library_distributed_app/data/models/create_borrow_request.dart';
import 'package:library_distributed_app/data/models/return_book_request.dart';
import 'package:library_distributed_app/data/services/borrow_service.dart';
import 'package:library_distributed_app/domain/entities/borrow_record.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:library_distributed_app/domain/repositories/borrow_repository.dart';
import 'package:result_dart/result_dart.dart';

class BorrowRepositoryImpl implements BorrowRepository {
  final BorrowService _borrowService;

  const BorrowRepositoryImpl(this._borrowService);

  @override
  Future<Result<BorrowRecordEntity>> createBorrow(
    CreateBorrowRequestEntity request,
  ) async {
    try {
      final requestModel = CreateBorrowRequestModel(
        readerId: request.readerId,
        bookCopyId: request.bookCopyId,
      );

      final response = await _borrowService.createBorrow(requestModel);

      if (response.isSuccessful && response.body != null) {
        final entity = _mapBorrowRecordModelToEntity(response.body!);
        return Success(entity);
      }

      return Failure(Exception('Failed to create borrow: ${response.error}'));
    } catch (e) {
      return Failure(Exception('Error creating borrow: $e'));
    }
  }

  @override
  Future<Result<void>> returnBook(int borrowId, String? bookCopyId) async {
    try {
      final requestModel = ReturnBookRequestModel(
        bookCopyId: bookCopyId,
        returnDate: DateTime.now().toIso8601String(),
      );

      final response = await _borrowService.returnBook(borrowId, requestModel);

      if (response.isSuccessful) {
        return const Success(unit);
      }

      return Failure(Exception('Failed to return book: ${response.error}'));
    } catch (e) {
      return Failure(Exception('Error returning book: $e'));
    }
  }

  @override
  Future<Result<(List<BorrowRecordEntity>, PagingEntity)>> getBorrowRecords({
    int page = 0,
    int size = kPaginationPageSize,
    String? search,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'size': size.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response = await _borrowService.getBorrows(params);

      if (response.isSuccessful && response.body != null) {
        final borrowRecordsModel = response.body!;

        final records = borrowRecordsModel.items
            .map((model) => _mapBorrowRecordModelToEntity(model))
            .toList();

        final paging = PagingEntity(
          currentPage: borrowRecordsModel.paging.page,
          pageSize: borrowRecordsModel.paging.size,
          totalPages: borrowRecordsModel.paging.totalPages ?? 1,
        );

        return Success((records, paging));
      }

      return Failure(
        Exception('Failed to get borrow records: ${response.error}'),
      );
    } catch (e) {
      return Failure(Exception('Error getting borrow records: $e'));
    }
  }

  @override
  Future<Result<(List<BorrowRecordWithDetailsEntity>, PagingEntity)>>
  getBorrowRecordsWithDetails({
    int page = 0,
    int size = kPaginationPageSize,
    String? search,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'size': size.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response = await _borrowService.getBorrowsWithDetails(params);

      if (response.isSuccessful && response.body != null) {
        final borrowRecordsWithDetailsModel = response.body!;

        final records = borrowRecordsWithDetailsModel.items
            .map((model) => _mapBorrowRecordWithDetailsModelToEntity(model))
            .toList();

        final paging = PagingEntity(
          currentPage: borrowRecordsWithDetailsModel.paging.page,
          pageSize: borrowRecordsWithDetailsModel.paging.size,
          totalPages: borrowRecordsWithDetailsModel.paging.totalPages ?? 1,
        );

        return Success((records, paging));
      }

      return Failure(
        Exception('Failed to get detailed borrow records: ${response.error}'),
      );
    } catch (e) {
      return Failure(Exception('Error getting detailed borrow records: $e'));
    }
  }

  @override
  Future<Result<BorrowRecordEntity>> getBorrowRecordById(int borrowId) async {
    try {
      // Since there's no specific endpoint, we can search in the list
      final result = await getBorrowRecords();

      return result.fold((data) {
        final (records, _) = data;
        final record = records.where((r) => r.borrowId == borrowId).firstOrNull;
        if (record != null) {
          return Success(record);
        }
        return Failure(Exception('Borrow record not found'));
      }, (error) => Failure(error));
    } catch (e) {
      return Failure(Exception('Error getting borrow record: $e'));
    }
  }

  @override
  Future<Result<bool>> hasActiveBorrows(String readerId) async {
    try {
      // Check if reader has any active borrows by querying all records
      final result = await getBorrowRecords(search: readerId);

      return result.fold((data) {
        final (records, _) = data;
        final hasActive = records
            .where((r) => r.readerId == readerId && !r.isReturned)
            .isNotEmpty;
        return Success(hasActive);
      }, (error) => Failure(error));
    } catch (e) {
      return Failure(Exception('Error checking active borrows: $e'));
    }
  }

  @override
  Future<Result<bool>> isBookCopyBorrowed(String bookCopyId) async {
    try {
      // Check if book copy is currently borrowed
      final result = await getBorrowRecords();

      return result.fold((data) {
        final (records, _) = data;
        final isBorrowed = records
            .where((r) => r.bookCopyId == bookCopyId && !r.isReturned)
            .isNotEmpty;
        return Success(isBorrowed);
      }, (error) => Failure(error));
    } catch (e) {
      return Failure(Exception('Error checking book copy borrow status: $e'));
    }
  }

  // Helper methods for mapping
  BorrowRecordEntity _mapBorrowRecordModelToEntity(BorrowRecordModel model) {
    return BorrowRecordEntity(
      borrowId: model.borrowId,
      readerId: model.readerId,
      bookCopyId: model.bookCopyId,
      branchSite: model.branchSite,
      borrowDate: model.borrowDate,
      returnDate: model.returnDate,
    );
  }

  BorrowRecordWithDetailsEntity _mapBorrowRecordWithDetailsModelToEntity(
    BorrowRecordWithDetailsModel model,
  ) {
    return BorrowRecordWithDetailsEntity(
      borrowId: model.borrowId,
      bookIsbn: model.bookIsbn,
      bookTitle: model.bookTitle,
      bookAuthor: model.bookAuthor,
      readerId: model.readerId,
      readerName: model.readerName,
      borrowDate: model.borrowDate,
      dueDate: model.dueDate,
      returnDate: model.returnDate,
      status: model.status,
      daysOverdue: model.daysOverdue,
      bookCopyId: model.bookCopyId,
      branch: model.branch,
    );
  }
}
