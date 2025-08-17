import 'package:library_distributed_app/data/models/book_copy.dart';
import 'package:library_distributed_app/data/services/book_copies_service.dart';
import 'package:library_distributed_app/domain/entities/book_copy.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:library_distributed_app/domain/repositories/book_copies_repository.dart';
import 'package:result_dart/result_dart.dart';

class BookCopiesRepositoryImpl implements BookCopiesRepository {
  final BookCopiesService _service;
  
  const BookCopiesRepositoryImpl(this._service);

  @override
  Future<Result<(List<BookCopyEntity>, PagingEntity)>> getBookCopies({
    int page = 0,
    int size = 20,
    String? search,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };
      
      if (search != null) params['search'] = search;

      final response = await _service.getList(params);
      
      if (response.isSuccessful && response.body != null) {
        final listResponse = response.body!;
        
        final bookCopies = listResponse.items
            .map((model) => _mapBookCopyModelToEntity(model))
            .toList();
        
        final paging = PagingEntity(
          currentPage: listResponse.paging.page,
          pageSize: listResponse.paging.size,
          totalPages: listResponse.paging.totalPages ?? 1,
        );
        
        return Success((bookCopies, paging));
      }
      
      return Failure(Exception('Failed to get book copies: ${response.error}'));
    } catch (e) {
      return Failure(Exception('Error getting book copies: $e'));
    }
  }

  @override
  Future<Result<BookCopyEntity>> getBookCopyById(String bookCopyId) async {
    try {
      final response = await _service.get(bookCopyId);
      
      if (response.isSuccessful && response.body != null) {
        return Success(_mapBookCopyModelToEntity(response.body!));
      }
      
      return Failure(Exception('Book copy not found'));
    } catch (e) {
      return Failure(Exception('Error getting book copy: $e'));
    }
  }

  @override
  Future<Result<BookCopyEntity>> createBookCopy(BookCopyEntity bookCopy) async {
    try {
      final model = _mapBookCopyEntityToModel(bookCopy);
      final response = await _service.createNew(model);
      
      if (response.isSuccessful && response.body != null) {
        return Success(_mapBookCopyModelToEntity(response.body!));
      }
      
      return Failure(Exception('Failed to create book copy: ${response.error}'));
    } catch (e) {
      return Failure(Exception('Error creating book copy: $e'));
    }
  }

  @override
  Future<Result<BookCopyEntity>> updateBookCopy(String bookCopyId, BookCopyEntity bookCopy) async {
    try {
      final model = _mapBookCopyEntityToModel(bookCopy);
      final response = await _service.update(bookCopyId, model);
      
      if (response.isSuccessful && response.body != null) {
        return Success(_mapBookCopyModelToEntity(response.body!));
      }
      
      return Failure(Exception('Failed to update book copy: ${response.error}'));
    } catch (e) {
      return Failure(Exception('Error updating book copy: $e'));
    }
  }

  @override
  Future<Result<void>> deleteBookCopy(String bookCopyId) async {
    try {
      final response = await _service.delete(bookCopyId);
      
      if (response.isSuccessful) {
        return const Success(unit);
      }
      
      return Failure(Exception('Failed to delete book copy: ${response.error}'));
    } catch (e) {
      return Failure(Exception('Error deleting book copy: $e'));
    }
  }

  @override
  Future<Result<bool>> isBookCopyAvailable(String bookCopyId) async {
    try {
      final result = await getBookCopyById(bookCopyId);
      return result.fold(
        (success) => Success(success.isAvailable),
        (failure) => Failure(failure),
      );
    } catch (e) {
      return Failure(Exception('Error checking book copy availability: $e'));
    }
  }

  // Legacy methods implementation
  @override
  Future<Result<BookCopiesEntity>> getList(PagingEntity paging) async {
    try {
      final result = await getBookCopies(
        page: paging.currentPage,
        size: paging.pageSize,
      );
      
      return result.fold(
        (success) {
          final (bookCopies, pagingInfo) = success;
          return Success(BookCopiesEntity(
            items: bookCopies,
            paging: pagingInfo,
          ));
        },
        (failure) => Failure(failure),
      );
    } catch (e) {
      return Failure(Exception('Error in legacy getList: $e'));
    }
  }

  @override
  Future<Result<BookCopyEntity>> get(String id) async {
    return await getBookCopyById(id);
  }

  @override
  Future<Result<String>> createNew(BookCopyEntity bookCopy) async {
    final result = await createBookCopy(bookCopy);
    return result.fold(
      (success) => Success(success.bookCopyId),
      (failure) => Failure(failure),
    );
  }

  @override
  Future<Result<String>> update(BookCopyEntity bookCopy) async {
    final result = await updateBookCopy(bookCopy.bookCopyId, bookCopy);
    return result.fold(
      (success) => Success(success.bookCopyId),
      (failure) => Failure(failure),
    );
  }

  @override
  Future<Result<String>> delete(String id) async {
    final result = await deleteBookCopy(id);
    return result.fold(
      (success) => Success(id),
      (failure) => Failure(failure),
    );
  }

  // Helper methods for mapping
  BookCopyEntity _mapBookCopyModelToEntity(BookCopyModel model) {
    return BookCopyEntity(
      bookCopyId: model.bookCopyId,
      isbn: model.isbn,
      branchSite: model.branchSite,
      status: model.status,
      bookTitle: model.bookTitle,
      bookAuthor: model.bookAuthor,
    );
  }

  BookCopyModel _mapBookCopyEntityToModel(BookCopyEntity entity) {
    return BookCopyModel(
      bookCopyId: entity.bookCopyId,
      isbn: entity.isbn,
      branchSite: entity.branchSite,
      status: entity.status,
      bookTitle: entity.bookTitle,
      bookAuthor: entity.bookAuthor,
    );
  }
}
