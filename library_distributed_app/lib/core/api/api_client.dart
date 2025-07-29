import 'package:chopper/chopper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/api/interceptor.dart';
import 'package:library_distributed_app/data/models/auth_info.dart';
import 'package:library_distributed_app/data/models/user_info.dart';
import 'package:library_distributed_app/data/services/auth_service.dart';
import 'package:library_distributed_app/core/utils/json_serializable_converter.dart';
import 'package:library_distributed_app/presentation/app/app_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/api_end_points.dart';
import '../constants/enums.dart';

part 'api_client.g.dart';

final _interceptors = [AuthInterceptor(), LoggingInterceptor()];

final _services = [AuthService.create()];

final _converter = JsonSerializableConverter({
  AuthInfoModel: AuthInfoModel.fromJson,
  UserInfoModel: UserInfoModel.fromJson,
});

@Riverpod(keepAlive: true)
ChopperClient apiClientProvider(Ref ref) {
  final site = ref.watch(librarySiteProvider);
  final baseUrl = switch (site) {
    Site.q1 => ApiEndPoints.siteQ1BaseUrl,
    Site.q3 => ApiEndPoints.siteQ3BaseUrl,
  };

  final client = ChopperClient(
    baseUrl: Uri.tryParse(baseUrl),
    services: _services,
    converter: _converter,
    interceptors: _interceptors,
  );

  ref.onDispose(client.dispose);

  return client;
}
