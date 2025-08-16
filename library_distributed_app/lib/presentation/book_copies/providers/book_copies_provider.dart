import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/domain/entities/book_copy.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'book_copies_provider.g.dart';

@riverpod
class BookCopies extends _$BookCopies {
  @override
  Future<BookCopiesEntity> build() async {
    await fetchData();
    return state.value ?? const BookCopiesEntity();
  }

  Future<void> fetchData([int page = 1]) async {}
}

@riverpod
Future<void> createBookCopy(Ref ref, BookCopyEntity bookCopy) async {}

@riverpod
Future<void> updateBookCopy(Ref ref, BookCopyEntity bookCopy) async {}

@riverpod
Future<void> deleteBookCopy(Ref ref, String id) async {}
