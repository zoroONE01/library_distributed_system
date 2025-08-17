import 'package:library_distributed_app/core/constants/enums.dart';
import 'package:library_distributed_app/data/models/transfer_book_request.dart';
import 'package:library_distributed_app/data/services/coordinator_service.dart';
import 'package:library_distributed_app/data/services/book_copies_service.dart';
import 'package:library_distributed_app/data/services/books_service.dart';
import 'package:library_distributed_app/domain/entities/book_transfer.dart';
import 'package:library_distributed_app/domain/repositories/book_transfer_repository.dart';
import 'package:result_dart/result_dart.dart';

/// Implementation of BookTransferRepository
/// Handles communication with coordinator service for 2PC distributed transactions
class BookTransferRepositoryImpl implements BookTransferRepository {
  final CoordinatorService _coordinatorService;
  final BookCopiesService _bookCopiesService;
  final BooksService _booksService;

  const BookTransferRepositoryImpl(
    this._coordinatorService,
    this._bookCopiesService,
    this._booksService,
  );

  @override
  Future<Result<BookTransferResponseEntity>> transferBookCopy(
    BookTransferRequestEntity request,
  ) async {
    try {
      // Convert domain entity to data model
      final requestModel = TransferBookRequestModel(
        bookCopyId: request.bookCopyId,
        fromSite: _siteToString(request.fromSite),
        toSite: _siteToString(request.toSite),
      );

      // Call coordinator service for distributed transaction
      final response = await _coordinatorService.transferBook(requestModel);

      if (response.isSuccessful && response.body != null) {
        // Convert response model to domain entity
        final responseModel = response.body!;
        final entity = BookTransferResponseEntity(
          message: responseModel.message,
          bookCopyId: responseModel.bookCopyId,
          fromSite: _stringToSite(responseModel.fromSite),
          toSite: _stringToSite(responseModel.toSite),
          protocol: responseModel.protocol,
          coordinator: responseModel.coordinator,
        );
        return Success(entity);
      } else {
        return Failure(Exception('Failed to transfer book: ${response.error}'));
      }
    } catch (e) {
      return Failure(Exception('Transfer book copy failed: $e'));
    }
  }

  @override
  Future<Result<BookCopyTransferInfoEntity>> getBookCopyTransferInfo(
    String bookCopyId,
  ) async {
    try {
      // Get book copy details from book copies service
      final bookCopyResponse = await _bookCopiesService.get(bookCopyId);

      if (!bookCopyResponse.isSuccessful || bookCopyResponse.body == null) {
        return Failure(Exception('Book copy not found: ${bookCopyResponse.error}'));
      }

      final bookCopy = bookCopyResponse.body!;
      
      // Get book details using ISBN
      final bookResponse = await _booksService.get(bookCopy.isbn);
      
      if (!bookResponse.isSuccessful || bookResponse.body == null) {
        return Failure(Exception('Book details not found for ISBN: ${bookCopy.isbn}'));
      }

      final book = bookResponse.body!;
      
      // Convert to transfer info entity
      final entity = BookCopyTransferInfoEntity(
        bookCopyId: bookCopy.bookCopyId,
        isbn: bookCopy.isbn,
        bookTitle: book.title,
        authorName: book.author,
        currentSite: bookCopy.branchSite,
        status: bookCopy.status,
      );
      return Success(entity);
    } catch (e) {
      return Failure(Exception('Failed to get book copy info: $e'));
    }
  }

  @override
  Future<Result<List<BookCopyTransferInfoEntity>>> searchTransferableBookCopies(
    String searchQuery,
  ) async {
    try {
      // Search available book copies
      final params = {
        'search': searchQuery,
        'page': 0,
        'limit': 20,
        'status': 'Có sẵn', // only available books
      };
      
      final response = await _bookCopiesService.getList(params);

      if (response.isSuccessful && response.body != null) {
        final bookCopiesResult = response.body!;
        final bookCopies = bookCopiesResult.items;
        
        // Get unique ISBNs to fetch book details
        final uniqueIsbns = bookCopies.map((bc) => bc.isbn).toSet().toList();
        
        // Fetch book details for all unique ISBNs
        final bookDetailsMap = <String, dynamic>{};
        for (final isbn in uniqueIsbns) {
          try {
            final bookResponse = await _booksService.get(isbn);
            if (bookResponse.isSuccessful && bookResponse.body != null) {
              bookDetailsMap[isbn] = bookResponse.body!;
            }
          } catch (e) {
            // Skip books with missing details
            continue;
          }
        }
        
        // Convert to transfer info entities
        final entities = <BookCopyTransferInfoEntity>[];
        for (final bookCopy in bookCopies) {
          final bookDetails = bookDetailsMap[bookCopy.isbn];
          if (bookDetails != null) {
            entities.add(BookCopyTransferInfoEntity(
              bookCopyId: bookCopy.bookCopyId,
              isbn: bookCopy.isbn,
              bookTitle: bookDetails.title,
              authorName: bookDetails.author,
              currentSite: bookCopy.branchSite,
              status: bookCopy.status,
            ));
          }
        }
        
        return Success(entities);
      } else {
        return Failure(Exception('Failed to search book copies: ${response.error}'));
      }
    } catch (e) {
      return Failure(Exception('Search transferable book copies failed: $e'));
    }
  }

  /// Convert Site enum to string for API
  String _siteToString(Site site) {
    switch (site) {
      case Site.q1:
        return 'Q1';
      case Site.q3:
        return 'Q3';
    }
  }

  /// Convert string to Site enum from API
  Site _stringToSite(String siteString) {
    return Site.fromString(siteString);
  }
}
