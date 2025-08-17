import 'package:library_distributed_app/domain/entities/book_transfer.dart';
import 'package:result_dart/result_dart.dart';

/// Repository interface for book transfer operations
/// Implements distributed transaction requirements for transferring books between sites
abstract class BookTransferRepository {
  /// Transfer a book copy from one site to another using 2PC protocol
  /// Only available for QUANLY (Manager) role
  /// FR: Distributed transaction demonstration using Two-Phase Commit
  Future<Result<BookTransferResponseEntity>> transferBookCopy(
    BookTransferRequestEntity request,
  );

  /// Get book copy information for transfer validation
  /// Checks if book copy exists and is available for transfer
  Future<Result<BookCopyTransferInfoEntity>> getBookCopyTransferInfo(
    String bookCopyId,
  );

  /// Search for book copies that are available for transfer
  /// Searches across all sites for QUANLY users
  Future<Result<List<BookCopyTransferInfoEntity>>> searchTransferableBookCopies(
    String searchQuery,
  );
}
