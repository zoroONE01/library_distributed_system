import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:library_distributed_app/core/api/api_client.dart';
import 'package:library_distributed_app/data/repositories/book_copies_repository.dart';
import 'package:library_distributed_app/data/services/book_copies_service.dart';
import 'package:library_distributed_app/domain/entities/book_copy.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:result_dart/result_dart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'book_copies_repository.g.dart';

@riverpod
BookCopiesRepository bookCopiesRepository(Ref ref) {
  return BookCopiesRepositoryImpl(
    ref.read(apiClientProvider).getService<BookCopiesService>(),
  );
}

abstract class BookCopiesRepository {
  Future<Result<BookCopiesEntity>> getList(PagingEntity paging);
  Future<Result<BookCopyEntity>> get(String id);
  Future<Result<String>> createNew(BookCopyEntity book);
  Future<Result<String>> update(BookCopyEntity book);
  Future<Result<String>> delete(String id);
}
