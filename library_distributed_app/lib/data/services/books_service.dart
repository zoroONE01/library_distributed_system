import 'package:chopper/chopper.dart';
import 'package:library_distributed_app/data/models/book.dart';
import 'package:library_distributed_app/data/models/books.dart';

part 'books_service.chopper.dart';

@ChopperApi(baseUrl: '/books')
abstract class BooksService extends ChopperService {
  @GET(path: '')
  Future<Response<BooksModel>> getList(@QueryMap() Map<String, dynamic> paging);

  @POST(path: '')
  Future<Response<BookModel>> createNew(@Body() BookModel model);

  @GET(path: '/{isbn}')
  Future<Response<BookModel>> get(@Path('id') String isbn);

  @PUT(path: '/{isbn}')
  Future<Response<BookModel>> update(
    @Path('isbn') String isbn,
    @Body() BookModel model,
  );

  @DELETE(path: '/{isbn}')
  Future<Response<void>> delete(@Path('isbn') String isbn);

  static BooksService create([ChopperClient? client]) => _$BooksService(client);
}
