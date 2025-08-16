import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/domain/entities/book.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'books_provider.g.dart';

@riverpod
class Books extends _$Books {
  @override
  Future<BooksEntity> build() async {
    await fetchData();
    return state.value ?? const BooksEntity();
  }

  Future<void> fetchData([int page = 0]) async {}
}

@riverpod
Future<void> createBook(Ref ref, BookEntity book) async {}

@riverpod
Future<void> updateBook(Ref ref, BookEntity book) async {}

@riverpod
Future<void> deleteBook(Ref ref, String id) async {}
