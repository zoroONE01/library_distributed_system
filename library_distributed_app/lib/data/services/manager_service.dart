import 'dart:async';
import 'package:chopper/chopper.dart';
import 'package:library_distributed_app/data/models/book.dart';
import 'package:library_distributed_app/data/models/book_search_result.dart';
import 'package:library_distributed_app/data/models/reader.dart';
import 'package:library_distributed_app/data/models/system_stats_response.dart';

part 'manager_service.chopper.dart';

@ChopperApi(baseUrl: '/manager')
abstract class ManagerService extends ChopperService {
  
  // Book management (FR10 - Create and view book catalog)
  @POST(path: '/books')
  Future<Response<BookModel>> createBook(@Body() BookModel book);

  @GET(path: '/books/{isbn}')
  Future<Response<BookModel>> getBook(@Path('isbn') String isbn);

  // Search available books system-wide (FR7)
  @GET(path: '/books/search')
  Future<Response<List<BookSearchResultModel>>> searchAvailableBooks(
    @Query('query') String searchQuery,
  );

  // System statistics (FR6)
  @GET(path: '/statistics')
  Future<Response<SystemStatsResponseModel>> getSystemStats();

  // System-wide readers query (FR11)
  @GET(path: '/readers')
  Future<Response<List<ReaderModel>>> getAllReaders(
    @Query('search') String? searchTerm,
  );

  static ManagerService create([ChopperClient? client]) =>
      _$ManagerService(client);
}
