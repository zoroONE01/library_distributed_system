import 'package:library_distributed_app/core/extensions/async_value_extension.dart';
import 'package:library_distributed_app/core/extensions/ref_extension.dart';
import 'package:library_distributed_app/data/models/book.dart';
import 'package:library_distributed_app/data/models/book_list.dart';
import 'package:library_distributed_app/data/models/paging.dart';
import 'package:library_distributed_app/domain/repositories/book_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'book_list_provider.g.dart';

@riverpod
class BookList extends _$BookList {
  @override
  Future<BookListModel> build() async {
    await fetchData(const PagingModel());
    return state.value ?? const BookListModel();
  }

  Future<void> refresh() async {
    await fetchData(const PagingModel());
  }

  Future<void> fetchData(PagingModel paging) async {
    state = state.loadingWithPrevious();
    state = await AsyncValue.guard(() {
      return ref.read(bookRepositoryProvider).getBookList(paging);
    });
  }
}

@riverpod
class Book extends _$Book {
  @override
  Future<BookModel> build([String? id]) async {
    if (id == null) {
      return const BookModel(quantity: 1);
    }
    await _fetchBook(id);
    return state.value ?? const BookModel(quantity: 1);
  }

  Future<void> _fetchBook(String id) async {
    state = state.loadingWithPrevious();
    state = await AsyncValue.guard(() {
      return ref.read(bookRepositoryProvider).getBookById(id);
    });
  }

  Future<void> performCreateNewBook() async {
    ref.startLoading();
    try {
      final book = state.value;
      if (book == null) {
        throw Exception('Book data is null');
      }
      final id = await ref.read(bookRepositoryProvider).addBook(book);
      state = AsyncValue.data(book.copyWith(id: id));

      // Refresh the book list after adding a new book
      await ref.read(bookListProvider.notifier).refresh();

      // Navigate back to the book list page
      if (ref.router.canPop()) ref.router.pop();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    } finally {
      ref.stopLoading();
    }
  }
}
