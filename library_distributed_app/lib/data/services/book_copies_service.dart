import 'package:chopper/chopper.dart';
import 'package:library_distributed_app/data/models/book_copy.dart';
import 'package:library_distributed_app/data/models/book_copies.dart';

part 'book_copies_service.chopper.dart';

@ChopperApi(baseUrl: '/books-copies')
abstract class BookCopiesService extends ChopperService {
  @GET(path: '')
  Future<Response<BookCopiesModel>> getList(
    @QueryMap() Map<String, dynamic> paging,
  );
  @GET(path: '/{isbn}')
  Future<Response<BookCopyModel>> get(@Path('isbn') String isbn);

  @POST(path: '')
  Future<Response<String>> createNew(@Body() BookCopyModel model);

  @PUT(path: '/{isbn}')
  Future<Response<BookCopyModel>> update(
    @Path('isbn') String isbn,
    @Body() BookCopyModel model,
  );

  @DELETE(path: '/{isbn}')
  Future<Response<void>> delete(@Path('isbn') String isbn);

  static BookCopiesService create([ChopperClient? client]) =>
      _$BookCopiesService(client);
}
