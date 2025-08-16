import 'package:chopper/chopper.dart';
import 'package:library_distributed_app/data/models/book.dart';
import 'package:library_distributed_app/data/models/books.dart';

part 'manager_service.chopper.dart';

@ChopperApi(baseUrl: '/manager')
abstract class ManagerService extends ChopperService {
  @POST(path: '/books')
  Future<Response<BooksModel>> createBook(@Body() BookModel book);

  @GET(path: '/books/{isbn}')
  Future<Response<BookModel>> getBook(@Path('id') String isbn);

  @PUT(path: '/books/{isbn}')
  Future<Response<BookModel>> updateBook(
    @Path('isbn') String isbn,
    @Body() BookModel book,
  );

  @DELETE(path: '/books/{isbn}')
  Future<Response<void>> deleteBook(@Path('isbn') String isbn);

  @POST(path: '/books/search')
  Future<Response<BooksModel>> searchBook(@Query('tenSach') String name);

  static ManagerService create([ChopperClient? client]) =>
      _$ManagerService(client);
}
