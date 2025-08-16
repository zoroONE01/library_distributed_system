import 'package:library_distributed_app/data/services/book_copies_service.dart';
import 'package:library_distributed_app/domain/entities/book_copy.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:library_distributed_app/domain/repositories/book_copy_repository.dart';
import 'package:result_dart/result_dart.dart';

class BookCopyRepositoryImpl implements BookCopyRepository {
  final BookCopiesService _service;
  const BookCopyRepositoryImpl(BookCopiesService service) : _service = service;
  @override
  Future<Result<String>> addBook(BookCopyEntity book) {
    // TODO: implement addBook
    throw UnimplementedError();
  }

  @override
  Future<Result<String>> deleteBook(String id) {
    // TODO: implement deleteBook
    throw UnimplementedError();
  }

  @override
  Future<Result<BookCopiesEntity>> getBookList(PagingEntity paging) {
    // TODO: implement getBookList
    throw UnimplementedError();
  }

  @override
  Future<Result<String>> updateBook(BookCopyEntity book) {
    // TODO: implement updateBook
    throw UnimplementedError();
  }
}
