import 'package:chopper/chopper.dart';
import 'package:library_distributed_app/data/models/book_copy.dart';
import 'package:library_distributed_app/data/models/book_copies.dart';

part 'book_copies_service.chopper.dart';

@ChopperApi(baseUrl: '/books-copies')
abstract class BookCopiesService extends ChopperService {
  @GET(path: '')
  Future<Response<BookCopiesModel>> getBookCopyList(
    @QueryMap() Map<String, dynamic> paging,
  );

  @POST(path: '')
  Future<Response<String>> addBookCopy(@Body() BookCopyModel book);

  @GET(path: '/{isbn}')
  Future<Response<BookCopyModel>> getBookCopy(@Path('isbn') String isbn);

  @PUT(path: '/{isbn}')
  Future<Response<BookCopyModel>> updateBookCopy(
    @Path('isbn') String isbn,
    @Body() BookCopyModel book,
  );

  @DELETE(path: '/{isbn}')
  Future<Response<void>> deleteBookCopy(@Path('isbn') String isbn);

  static BookCopiesService create([ChopperClient? client]) =>
      _$BookCopiesService(client);
}
