import 'package:chopper/chopper.dart';
import 'package:library_distributed_app/data/models/book.dart';
import 'package:library_distributed_app/data/models/book_list.dart';

part 'book_service.chopper.dart';

@ChopperApi(baseUrl: '/books')
abstract class BookService extends ChopperService {
  @GET(path: '')
  Future<Response<BookListModel>> getBookList(
    @QueryMap() Map<String, dynamic> paging,
  );

  @POST(path: '')
  Future<Response<BookModel>> addBook(@Body() BookModel book);

  @GET(path: '/{id}')
  Future<Response<BookModel>> getBook(@Path('id') String id);

  @PUT(path: '/{id}')
  Future<Response<BookModel>> updateBook(
    @Path('id') String id,
    @Body() BookModel book,
  );

  @DELETE(path: '/{id}')
  Future<Response<void>> deleteBook(@Path('id') String id);

  static BookService create([ChopperClient? client]) => _$BookService(client);
}
