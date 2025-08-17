import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:library_distributed_app/data/models/system_stats_response.dart';
import 'package:library_distributed_app/data/models/readers_with_stats.dart';

part 'stats_service.chopper.dart';

@ChopperApi(baseUrl: '/stats')
abstract class StatsService extends ChopperService {
  
  @GET(path: '/readers')
  Future<Response<ReadersWithStatsModel>> getReadersWithStats(
    @QueryMap() Map<String, dynamic> params,
  );

  @GET(path: '/system')
  Future<Response<SystemStatsResponseModel>> getSystemStats();

  static StatsService create([ChopperClient? client]) => _$StatsService(client);
}