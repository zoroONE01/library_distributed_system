import 'dart:async';

import 'package:library_distributed_app/domain/entities/book.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:library_distributed_app/domain/repositories/books_repository.dart';
import 'package:library_distributed_app/domain/usecases/usecases.dart';
import 'package:result_dart/result_dart.dart';

class GetBooksUsecase extends UseCaseWithParams<BooksEntity, PagingEntity> {
  const GetBooksUsecase(this._repository);
  final BooksRepository _repository;

  @override
  FutureOr<Result<BooksEntity>> call(PagingEntity params) {
    return _repository.getList(params);
  }
}

class GetBookByIdUsecase extends UseCaseWithParams<BookEntity, String> {
  const GetBookByIdUsecase(this._repository);
  final BooksRepository _repository;

  @override
  FutureOr<Result<BookEntity>> call(String params) {
    return _repository.get(params);
  }
}
