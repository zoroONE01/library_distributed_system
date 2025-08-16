import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:library_distributed_app/core/api/api_client.dart';
import 'package:library_distributed_app/data/repositories/books_repository.dart';
import 'package:library_distributed_app/data/services/books_service.dart';
import 'package:library_distributed_app/domain/entities/book.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:result_dart/result_dart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'books_repository.g.dart';

@riverpod
BooksRepository booksRepository(Ref ref) {
  return BookRepositoryImpl(
    ref.read(apiClientProvider).getService<BooksService>(),
  );
}

abstract class BooksRepository {
  Future<Result<BooksEntity>> getList(PagingEntity paging);
  Future<Result<BookEntity>> get(String id);
  Future<Result<String>> createNew(BookEntity book);
  Future<Result<String>> update(BookEntity book);
  Future<Result<String>> delete(String id);
}
