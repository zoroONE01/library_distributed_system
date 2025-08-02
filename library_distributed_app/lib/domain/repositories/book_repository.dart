import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:library_distributed_app/core/api/api_client.dart';
import 'package:library_distributed_app/data/models/book.dart';
import 'package:library_distributed_app/data/models/book_list.dart';
import 'package:library_distributed_app/data/models/paging.dart';
import 'package:library_distributed_app/data/repositories/book_repository.dart';
import 'package:library_distributed_app/data/services/book_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'book_repository.g.dart';

@riverpod
BookRepository bookRepository(Ref ref) {
  return BookRepositoryImpl(
    ref.read(apiClientProvider).getService<BookService>(),
  );
}

abstract class BookRepository {
  Future<BookListModel> getBookList(PagingModel paging);
  Future<BookModel> getBookById(String id);
  Future<String> addBook(BookModel book);
  Future<String> updateBook(BookModel book);
  Future<String> deleteBook(String id);
}
