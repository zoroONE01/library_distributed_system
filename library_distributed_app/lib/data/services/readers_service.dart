import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:library_distributed_app/data/models/reader.dart';
import 'package:library_distributed_app/data/models/readers.dart';

part 'readers_service.chopper.dart';

@ChopperApi(baseUrl: '/readers')
abstract class ReadersService extends ChopperService {
  @GET(path: '')
  Future<Response<ReadersModel>> getList(
    @QueryMap() Map<String, dynamic> params,
  );

  @GET(path: '/{readerId}')
  Future<Response<ReaderModel>> get(@Path('readerId') String readerId);

  @POST(path: '')
  Future<Response<ReaderModel>> createNew(@Body() ReaderModel model);

  @PUT(path: '/{readerId}')
  Future<Response<ReaderModel>> update(
    @Path('readerId') String readerId,
    @Body() ReaderModel model,
  );

  @DELETE(path: '/{readerId}')
  Future<Response<void>> delete(@Path('readerId') String readerId);

  static ReadersService create([ChopperClient? client]) => _$ReadersService(client);
}