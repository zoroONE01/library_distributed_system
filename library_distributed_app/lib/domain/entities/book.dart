import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:library_distributed_app/domain/entities/branch.dart';

class BookEntity {
  final String isbn;
  final String title;
  final String author;

  const BookEntity({this.isbn = '', this.title = '', this.author = ''});
}

class BookWithAvailabilityEntity {
  final String isbn;
  final String title;
  final String author;
  final int availableCount;
  final int totalCount;
  final int borrowedCount;

  const BookWithAvailabilityEntity({
    this.isbn = '',
    this.title = '',
    this.author = '',
    this.availableCount = 0,
    this.totalCount = 0,
    this.borrowedCount = 0,
  });

  bool get isAvailable => availableCount > 0;
}

class BookSearchResultEntity {
  final BookEntity book;
  final List<BranchEntity> availableBranches;
  final int availableCount;

  const BookSearchResultEntity({
    required this.book,
    this.availableBranches = const [],
    this.availableCount = 0,
  });

  bool get isAvailable => availableCount > 0;
}

class BooksEntity {
  final List<BookEntity> items;
  final PagingEntity paging;

  const BooksEntity({
    this.items = const [],
    this.paging = const PagingEntity(),
  });
}
