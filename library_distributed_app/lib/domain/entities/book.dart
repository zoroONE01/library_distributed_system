import 'package:library_distributed_app/domain/entities/paging.dart';

class BookEntity {
  final String isbn;
  final String title;
  final String author;

  const BookEntity({this.isbn = '', this.title = '', this.author = ''});
}

class BooksEntity {
  final List<BookEntity> items;
  final PagingEntity paging;

  const BooksEntity({
    this.items = const [],
    this.paging = const PagingEntity(),
  });
}
