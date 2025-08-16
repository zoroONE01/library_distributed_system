import 'package:library_distributed_app/data/services/books_service.dart';
import 'package:library_distributed_app/domain/entities/book.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:library_distributed_app/domain/repositories/book_repository.dart';
import 'package:result_dart/result_dart.dart';

class BookRepositoryImpl implements BookRepository {
  const BookRepositoryImpl(BooksService service) : _service = service;

  final BooksService _service;

  @override
  Future<Result<String>> addBook(BookEntity book) {
    // TODO: implement addBook
    throw UnimplementedError();
  }

  @override
  Future<Result<String>> deleteBook(String id) {
    // TODO: implement deleteBook
    throw UnimplementedError();
  }

  @override
  Future<Result<BooksEntity>> getBookList(PagingEntity paging) {
    // TODO: implement getBookList
    throw UnimplementedError();
  }

  @override
  Future<Result<String>> updateBook(BookEntity book) {
    // TODO: implement updateBook
    throw UnimplementedError();
  }
}
