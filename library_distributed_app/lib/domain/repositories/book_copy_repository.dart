import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:library_distributed_app/core/api/api_client.dart';
import 'package:library_distributed_app/data/repositories/book_copy_repository.dart';
import 'package:library_distributed_app/data/services/book_copies_service.dart';
import 'package:library_distributed_app/domain/entities/book_copy.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:result_dart/result_dart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'book_copy_repository.g.dart';

@riverpod
BookCopyRepository bookCopyRepository(Ref ref) {
  return BookCopyRepositoryImpl(
    ref.read(apiClientProvider).getService<BookCopiesService>(),
  );
}

abstract class BookCopyRepository {
  Future<Result<BookCopiesEntity>> getBookList(PagingEntity paging);
  Future<Result<String>> addBook(BookCopyEntity book);
  Future<Result<String>> updateBook(BookCopyEntity book);
  Future<Result<String>> deleteBook(String id);
}
