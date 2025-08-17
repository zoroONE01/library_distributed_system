import 'package:library_distributed_app/core/constants/enums.dart';

/// Entity for book transfer request
/// Implements distributed transaction requirements for FR - book transfer between sites
class BookTransferRequestEntity {
  final String bookCopyId;
  final Site fromSite;
  final Site toSite;

  const BookTransferRequestEntity({
    required this.bookCopyId,
    required this.fromSite,
    required this.toSite,
  });

  /// Validation for transfer request
  bool get isValid => bookCopyId.isNotEmpty && fromSite != toSite;

  @override
  String toString() {
    return 'BookTransferRequestEntity(bookCopyId: $bookCopyId, fromSite: $fromSite, toSite: $toSite)';
  }
}

/// Entity for book transfer response
/// Contains result information from 2PC distributed transaction
class BookTransferResponseEntity {
  final String message;
  final String bookCopyId;
  final Site fromSite;
  final Site toSite;
  final String protocol;
  final String coordinator;

  const BookTransferResponseEntity({
    required this.message,
    required this.bookCopyId,
    required this.fromSite,
    required this.toSite,
    required this.protocol,
    required this.coordinator,
  });

  bool get isSuccess => message.contains('successfully') || message.contains('thành công');

  @override
  String toString() {
    return 'BookTransferResponseEntity(message: $message, bookCopyId: $bookCopyId, fromSite: $fromSite, toSite: $toSite, protocol: $protocol)';
  }
}

/// Entity for book copy information used in transfer operations
class BookCopyTransferInfoEntity {
  final String bookCopyId;
  final String isbn;
  final String bookTitle;
  final String authorName;
  final Site currentSite;
  final String status;

  const BookCopyTransferInfoEntity({
    required this.bookCopyId,
    required this.isbn,
    required this.bookTitle,
    required this.authorName,
    required this.currentSite,
    required this.status,
  });

  /// Check if book copy is available for transfer
  bool get isAvailableForTransfer => status == 'Có sẵn';

  @override
  String toString() {
    return 'BookCopyTransferInfoEntity(bookCopyId: $bookCopyId, isbn: $isbn, bookTitle: $bookTitle, currentSite: $currentSite, status: $status)';
  }
}
