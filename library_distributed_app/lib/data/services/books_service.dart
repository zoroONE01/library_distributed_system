import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:library_distributed_app/data/models/book.dart';
import 'package:library_distributed_app/data/models/books.dart';

part 'books_service.chopper.dart';

@ChopperApi(baseUrl: '/books')
abstract class BooksService extends ChopperService {
  @GET(path: '')
  Future<Response<BooksModel>> getList(
    @QueryMap() Map<String, dynamic> params,
  );

  @GET(path: '/{isbn}')
  Future<Response<BookModel>> get(@Path('isbn') String isbn);

  @GET(path: '/{isbn}/available')
  Future<Response<BookModel>> getAvailableCopy(@Path('isbn') String isbn);

  static BooksService create([ChopperClient? client]) => _$BooksService(client);
}
