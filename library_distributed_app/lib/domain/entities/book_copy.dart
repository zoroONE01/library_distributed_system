import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:library_distributed_app/core/constants/enums.dart';

class BookCopyEntity {
  final String bookCopyId;
  final String isbn;
  final Site branchSite;
  final BookStatus status;

  const BookCopyEntity({
    required this.bookCopyId,
    required this.isbn,
    required this.branchSite,
    required this.status,
  });

  bool get isAvailable => status == BookStatus.available;
  bool get isBorrowed => status == BookStatus.borrowed;
  bool get isDamaged => status == BookStatus.damaged;
}

class BookCopiesEntity {
  final List<BookCopyEntity> items;
  final PagingEntity paging;

  const BookCopiesEntity({
    this.items = const [],
    this.paging = const PagingEntity(),
  });
}
