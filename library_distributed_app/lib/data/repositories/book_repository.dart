import 'package:library_distributed_app/data/models/book.dart';
import 'package:library_distributed_app/data/models/book_list.dart';
import 'package:library_distributed_app/data/models/paging.dart';
import 'package:library_distributed_app/data/services/book_service.dart';
import 'package:library_distributed_app/domain/repositories/book_repository.dart';

class BookRepositoryImpl implements BookRepository {
  const BookRepositoryImpl(this._service);
  final BookService _service;

  @override
  Future<String> addBook(BookModel book) async {
    try {
      final response = await _service.addBook(book);
      if (response.isSuccessful && response.body != null) {
        return response.body!.id;
      } else {
        throw Exception('Failed to add book');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> deleteBook(String id) async {
    try {
      final response = await _service.deleteBook(id);
      if (response.isSuccessful) {
        return id;
      } else {
        throw Exception('Failed to delete book');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BookModel> getBookById(String id) async {
    try {
      final response = await _service.getBook(id);
      if (response.isSuccessful && response.body != null) {
        return response.body!;
      } else {
        throw Exception('Failed to get book');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BookListModel> getBookList(PagingModel paging) async {
    try {
      final response = await _service.getBookList(paging);
      if (response.isSuccessful && response.body != null) {
        return response.body!;
      } else {
        throw Exception('Failed to get book list');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> updateBook(BookModel book) async {
    try {
      final response = await _service.updateBook(book.id, book);
      if (response.isSuccessful && response.body != null) {
        return response.body!.id;
      } else {
        throw Exception('Failed to update book');
      }
    } catch (e) {
      rethrow;
    }
  }
}
