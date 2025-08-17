import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:library_distributed_app/data/models/book_copy.dart';
import 'package:library_distributed_app/data/models/list_response.dart';

part 'book_copies_service.chopper.dart';

@ChopperApi(baseUrl: '/book-copies')
abstract class BookCopiesService extends ChopperService {
  @GET(path: '')
  Future<Response<ListResponse<BookCopyModel>>> getList(
    @QueryMap() Map<String, dynamic> params,
  );
  
  @GET(path: '/{bookCopyId}')
  Future<Response<BookCopyModel>> get(@Path('bookCopyId') String bookCopyId);

  @POST(path: '')
  Future<Response<BookCopyModel>> createNew(@Body() BookCopyModel model);

  @PUT(path: '/{bookCopyId}')
  Future<Response<BookCopyModel>> update(
    @Path('bookCopyId') String bookCopyId,
    @Body() BookCopyModel model,
  );

  @DELETE(path: '/{bookCopyId}')
  Future<Response<void>> delete(@Path('bookCopyId') String bookCopyId);

  static BookCopiesService create([ChopperClient? client]) =>
      _$BookCopiesService(client);
}
