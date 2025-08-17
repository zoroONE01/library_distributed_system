import 'package:library_distributed_app/core/constants/enums.dart';

class BorrowRecordEntity {
  final int borrowId;
  final String readerId;
  final String bookCopyId;
  final Site branchSite;
  final String borrowDate;
  final String? returnDate;

  const BorrowRecordEntity({
    required this.borrowId,
    required this.readerId,
    required this.bookCopyId,
    required this.branchSite,
    required this.borrowDate,
    this.returnDate,
  });

  bool get isReturned => returnDate != null;
}

class BorrowRecordWithDetailsEntity {
  final int borrowId;
  final String bookIsbn;
  final String bookTitle;
  final String bookAuthor;
  final String readerId;
  final String readerName;
  final String borrowDate;
  final String dueDate;
  final String? returnDate;
  final BorrowStatus status;
  final int daysOverdue;
  final String bookCopyId;
  final Site branch;

  const BorrowRecordWithDetailsEntity({
    required this.borrowId,
    required this.bookIsbn,
    required this.bookTitle,
    required this.bookAuthor,
    required this.readerId,
    required this.readerName,
    required this.borrowDate,
    required this.dueDate,
    this.returnDate,
    required this.status,
    this.daysOverdue = 0,
    required this.bookCopyId,
    required this.branch,
  });

  bool get isReturned => returnDate != null;
  bool get isOverdue => daysOverdue > 0;
}

class CreateBorrowRequestEntity {
  final String readerId;
  final String bookCopyId;

  const CreateBorrowRequestEntity({
    required this.readerId,
    required this.bookCopyId,
  });
}