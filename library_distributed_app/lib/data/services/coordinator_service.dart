import 'dart:async';
import 'package:chopper/chopper.dart';
import 'package:library_distributed_app/data/models/transfer_book_request.dart';
import 'package:library_distributed_app/data/models/transfer_book_response.dart';

part 'coordinator_service.chopper.dart';

@ChopperApi(baseUrl: '/coordinator')
abstract class CoordinatorService extends ChopperService {
  
  // Book transfer using 2PC protocol
  @POST(path: '/transfer-book')
  Future<Response<TransferBookResponseModel>> transferBook(
    @Body() TransferBookRequestModel request,
  );

  static CoordinatorService create([ChopperClient? client]) =>
      _$CoordinatorService(client);
}
