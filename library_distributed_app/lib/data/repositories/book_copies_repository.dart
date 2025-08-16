import 'package:library_distributed_app/data/models/paging.dart';
import 'package:library_distributed_app/data/services/book_copies_service.dart';
import 'package:library_distributed_app/domain/entities/book_copy.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:library_distributed_app/domain/repositories/book_copies_repository.dart';
import 'package:result_dart/result_dart.dart';

class BookCopiesRepositoryImpl implements BookCopiesRepository {
  final BookCopiesService _service;
  const BookCopiesRepositoryImpl(BookCopiesService service)
    : _service = service;

  @override
  Future<Result<String>> createNew(BookCopyEntity book) {
    // TODO: implement create
    throw UnimplementedError();
  }

  @override
  Future<Result<String>> delete(String id) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<Result<BookCopyEntity>> get(String id) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future<Result<BookCopiesEntity>> getList(PagingEntity paging) async {
    throw UnimplementedError();

    // try {
    //   // final pagingModel = PagingModel.fromEntity(paging);
    //   // final response = await _service.getList(pagingModel.toJson());
    //   // if (response.isSuccessful) {
    //   //   final bookCopiesModel = response.body;
    //   //   return Success(BookCopiesEntity.fromModel(response.body!));
    //   // } else {
    //   //   return Result.failure(Exception('Failed to fetch book copies'));
    //   // }
    // } catch (e) {
    //   return Result.failure(e);
    // }
  }

  @override
  Future<Result<String>> update(BookCopyEntity book) {
    // TODO: implement update
    throw UnimplementedError();
  }
}
