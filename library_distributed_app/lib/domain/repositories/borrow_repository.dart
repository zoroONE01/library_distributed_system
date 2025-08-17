import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/api/api_client.dart';
import 'package:library_distributed_app/data/repositories/borrow_repository.dart';
import 'package:library_distributed_app/data/services/borrow_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:library_distributed_app/domain/entities/borrow_record.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:result_dart/result_dart.dart';

part 'borrow_repository.g.dart';

/// Repository interface for Borrowing operations (FR2, FR3, FR4, FR6)
/// - FR2: Lập phiếu mượn sách (THUTHU)
/// - FR3: Ghi nhận trả sách (THUTHU)
/// - FR4: Tra cứu cục bộ (THUTHU)
/// - FR6: Thống kê toàn hệ thống (QUANLY)
abstract class BorrowRepository {
  /// Create new borrow record (FR2 - THUTHU only)
  Future<Result<BorrowRecordEntity>> createBorrow(
    CreateBorrowRequestEntity request,
  );

  /// Return borrowed book (FR3 - THUTHU only)
  Future<Result<void>> returnBook(int borrowId, String? bookCopyId);

  /// Get borrow records with pagination (FR4 - local access for THUTHU)
  Future<Result<(List<BorrowRecordEntity>, PagingEntity)>> getBorrowRecords({
    int page = 0,
    int size = 20,
    String? search,
  });

  /// Get detailed borrow records with book and reader info
  Future<Result<(List<BorrowRecordWithDetailsEntity>, PagingEntity)>>
  getBorrowRecordsWithDetails({int page = 0, int size = 20, String? search});

  /// Get borrow record by ID
  Future<Result<BorrowRecordEntity>> getBorrowRecordById(int borrowId);

  /// Check if reader has active borrows (for reader deletion validation)
  Future<Result<bool>> hasActiveBorrows(String readerId);

  /// Check if book copy is currently borrowed (for book copy deletion validation)
  Future<Result<bool>> isBookCopyBorrowed(String bookCopyId);
}

@riverpod
BorrowRepository borrowRepository(Ref ref) {
  final borrowService = ref.read(apiClientProvider).getService<BorrowService>();
  return BorrowRepositoryImpl(borrowService);
}
