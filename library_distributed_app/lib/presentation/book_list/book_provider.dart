import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/extensions/async_value_extension.dart';
import 'package:library_distributed_app/core/extensions/ref_extension.dart';
import 'package:library_distributed_app/data/models/book.dart';
import 'package:library_distributed_app/data/models/book_list.dart';
import 'package:library_distributed_app/data/models/paging.dart';
import 'package:library_distributed_app/domain/repositories/book_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'book_provider.g.dart';

@riverpod
class BookList extends _$BookList {
  @override
  Future<BookListModel> build() async {
    await fetchData();
    return state.value ?? const BookListModel();
  }

  Future<void> fetchData([PagingModel paging = const PagingModel()]) async {
    state = state.loadingWithPrevious();
    state = await AsyncValue.guard(() {
      return ref.read(bookRepositoryProvider).getBookList(paging);
    });
  }
}

@riverpod
Future<void> deleteBook(Ref ref, String id) async {
  try {
    await ref.read(bookRepositoryProvider).deleteBook(id);
    await ref.read(bookListProvider.notifier).fetchData();
  } catch (e, stackTrace) {
    throw AsyncError(e, stackTrace);
  }
}

@riverpod
Future<void> createBook(Ref ref, BookModel book) async {
  try {
    await ref.read(bookRepositoryProvider).addBook(book);
    await ref.read(bookListProvider.notifier).fetchData();
  } catch (e, stackTrace) {
    throw AsyncError(e, stackTrace);
  }
}

@riverpod
class EditBook extends _$EditBook {
  @override
  Future<BookModel> build(String id) async {
    await _fetchBook(id);
    if (state.value == null) {
      throw Exception('Book not found');
    }
    return state.value!;
  }

  Future<void> _fetchBook(String id) async {
    state = state.loadingWithPrevious();
    state = await AsyncValue.guard(() {
      return ref.read(bookRepositoryProvider).getBookById(id);
    });
  }

  Future<void> performUpdate() async {
    ref.startLoading();
    state = state.loadingWithPrevious();
    try {
      await ref.read(bookRepositoryProvider).updateBook(state.value!);
      await ref.read(bookListProvider.notifier).fetchData();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    } finally {
      ref.stopLoading();
    }
  }
}
