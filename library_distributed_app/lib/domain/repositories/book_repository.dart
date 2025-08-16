import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:library_distributed_app/core/api/api_client.dart';
import 'package:library_distributed_app/data/repositories/book_repository.dart';
import 'package:library_distributed_app/data/services/books_service.dart';
import 'package:library_distributed_app/domain/entities/book.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:result_dart/result_dart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'book_repository.g.dart';

@riverpod
BookRepository bookRepository(Ref ref) {
  return BookRepositoryImpl(
    ref.read(apiClientProvider).getService<BooksService>(),
  );
}

abstract class BookRepository {
  Future<Result<BooksEntity>> getBookList(PagingEntity paging);
  Future<Result<String>> addBook(BookEntity book);
  Future<Result<String>> updateBook(BookEntity book);
  Future<Result<String>> deleteBook(String id);
}
