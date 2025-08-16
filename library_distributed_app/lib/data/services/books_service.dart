import 'package:chopper/chopper.dart';
import 'package:library_distributed_app/data/models/book.dart';
import 'package:library_distributed_app/data/models/books.dart';

part 'books_service.chopper.dart';

@ChopperApi(baseUrl: '/books')
abstract class BooksService extends ChopperService {
  @GET(path: '')
  Future<Response<BooksModel>> getBookList(
    @QueryMap() Map<String, dynamic> paging,
  );

  @POST(path: '')
  Future<Response<BookModel>> addBook(@Body() BookModel book);

  @GET(path: '/{isbn}')
  Future<Response<BookModel>> getBook(@Path('id') String isbn);

  @PUT(path: '/{isbn}')
  Future<Response<BookModel>> updateBook(
    @Path('isbn') String isbn,
    @Body() BookModel book,
  );

  @DELETE(path: '/{isbn}')
  Future<Response<void>> deleteBook(@Path('isbn') String isbn);

  static BooksService create([ChopperClient? client]) => _$BooksService(client);
}
