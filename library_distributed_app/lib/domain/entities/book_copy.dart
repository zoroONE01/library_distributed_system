import 'package:library_distributed_app/domain/entities/paging.dart';

class BookCopyEntity {
  final String isbn;
  final String title;
  final String author;
  final String description;
  final int totalCount;
  final int availableCount;

  const BookCopyEntity({
    this.isbn = '',
    this.title = '',
    this.author = '',
    this.description = '',
    this.totalCount = 0,
    this.availableCount = 0,
  });
}

class BookCopiesEntity {
  final List<BookCopyEntity> items;
  final PagingEntity paging;

  const BookCopiesEntity({
    this.items = const [],
    this.paging = const PagingEntity(),
  });
}
