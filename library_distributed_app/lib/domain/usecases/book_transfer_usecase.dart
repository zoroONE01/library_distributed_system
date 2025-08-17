import 'package:library_distributed_app/domain/entities/book_transfer.dart';
import 'package:library_distributed_app/domain/repositories/book_transfer_repository.dart';
import 'package:library_distributed_app/domain/usecases/usecases.dart';
import 'package:result_dart/result_dart.dart';

/// FR: Transfer book copy between sites using 2PC protocol
/// Only available for QUANLY (Manager) role
/// Demonstrates distributed transaction management
class TransferBookCopyUseCase
    extends UseCaseWithParams<BookTransferResponseEntity, BookTransferRequestEntity> {
  final BookTransferRepository repository;

  TransferBookCopyUseCase(this.repository);

  @override
  Future<Result<BookTransferResponseEntity>> call(BookTransferRequestEntity params) async {
    // Validate request before processing
    if (!params.isValid) {
      return Failure(Exception('Invalid transfer request: source and destination sites must be different'));
    }

    if (params.bookCopyId.isEmpty) {
      return Failure(Exception('Book copy ID is required'));
    }

    try {
      // First, validate that the book copy exists and is available for transfer
      final bookInfoResult = await repository.getBookCopyTransferInfo(params.bookCopyId);
      
      if (bookInfoResult.isError()) {
        return Failure(Exception('Book copy not found or not available for transfer'));
      }

      final bookInfo = bookInfoResult.getOrThrow();
      
      // Verify the book is at the source site
      if (bookInfo.currentSite != params.fromSite) {
        return Failure(Exception('Book copy is not located at the specified source site'));
      }

      // Verify the book is available for transfer
      if (!bookInfo.isAvailableForTransfer) {
        return Failure(Exception('Book copy is not available for transfer (status: ${bookInfo.status})'));
      }

      // Execute the transfer using 2PC protocol
      return await repository.transferBookCopy(params);
      
    } catch (e) {
      return Failure(Exception('Failed to transfer book copy: $e'));
    }
  }
}

/// Get book copy transfer information for validation
class GetBookCopyTransferInfoUseCase
    extends UseCaseWithParams<BookCopyTransferInfoEntity, String> {
  final BookTransferRepository repository;

  GetBookCopyTransferInfoUseCase(this.repository);

  @override
  Future<Result<BookCopyTransferInfoEntity>> call(String bookCopyId) async {
    if (bookCopyId.isEmpty) {
      return Failure(Exception('Book copy ID is required'));
    }

    try {
      return await repository.getBookCopyTransferInfo(bookCopyId);
    } catch (e) {
      return Failure(Exception('Failed to get book copy information: $e'));
    }
  }
}

/// Search for transferable book copies across all sites
/// Only available for QUANLY (Manager) role
class SearchTransferableBookCopiesUseCase
    extends UseCaseWithParams<List<BookCopyTransferInfoEntity>, String> {
  final BookTransferRepository repository;

  SearchTransferableBookCopiesUseCase(this.repository);

  @override
  Future<Result<List<BookCopyTransferInfoEntity>>> call(String searchQuery) async {
    if (searchQuery.trim().isEmpty) {
      return const Success([]); // Return empty list for empty search
    }

    try {
      return await repository.searchTransferableBookCopies(searchQuery.trim());
    } catch (e) {
      return Failure(Exception('Failed to search transferable book copies: $e'));
    }
  }
}
