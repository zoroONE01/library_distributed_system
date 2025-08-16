import 'package:library_distributed_app/data/services/books_service.dart';
import 'package:library_distributed_app/domain/entities/book.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:library_distributed_app/domain/repositories/books_repository.dart';
import 'package:result_dart/result_dart.dart';

class BookRepositoryImpl implements BooksRepository {
  const BookRepositoryImpl(BooksService service) : _service = service;

  final BooksService _service;

  @override
  Future<Result<String>> createNew(BookEntity book) {
    // TODO: implement addBook
    throw UnimplementedError();
  }

  @override
  Future<Result<String>> delete(String id) {
    // TODO: implement deleteBook
    throw UnimplementedError();
  }

  @override
  Future<Result<BooksEntity>> getList(PagingEntity paging) {
    // TODO: implement getBookList
    throw UnimplementedError();
  }

  @override
  Future<Result<String>> update(BookEntity book) {
    // TODO: implement updateBook
    throw UnimplementedError();
  }

  @override
  Future<Result<BookEntity>> get(String id) {
    // TODO: implement get
    throw UnimplementedError();
  }
}
