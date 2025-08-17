import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:library_distributed_app/data/models/borrow_record.dart';
import 'package:library_distributed_app/data/models/create_borrow_request.dart';
import 'package:library_distributed_app/data/models/return_book_request.dart';
import 'package:library_distributed_app/data/models/borrow_records_simple.dart';
import 'package:library_distributed_app/data/models/borrow_records.dart';

part 'borrow_service.chopper.dart';

@ChopperApi(baseUrl: '/borrow')
abstract class BorrowService extends ChopperService {
  
  @POST(path: '')
  Future<Response<BorrowRecordModel>> createBorrow(@Body() CreateBorrowRequestModel request);

  @PUT(path: '/return/{borrowId}')
  Future<Response<void>> returnBook(
    @Path('borrowId') int borrowId,
    @Body() ReturnBookRequestModel? request,
  );

  @GET(path: '')
  Future<Response<BorrowRecordsSimpleModel>> getBorrows(
    @QueryMap() Map<String, dynamic> params,
  );

  @GET(path: '/detailed')
  Future<Response<BorrowRecordsModel>> getBorrowsWithDetails(
    @QueryMap() Map<String, dynamic> params,
  );

  static BorrowService create([ChopperClient? client]) => _$BorrowService(client);
}