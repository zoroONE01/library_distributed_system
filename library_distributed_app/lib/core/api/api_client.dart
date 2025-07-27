import 'package:chopper/chopper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/api/interceptor.dart';
import 'package:library_distributed_app/core/utils/local_storage_manager.dart';
import 'package:library_distributed_app/data/services/auth_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/api_end_points.dart';
import '../constants/enums.dart';

part 'api_client.g.dart';

final _services = [AuthService.create()];

@riverpod
ChopperClient apiClientProvider(Ref ref) {
  final localSiteValue = localStorage.read(LocalStorageKeys.site);
  final currentSite = Site.fromString(localSiteValue);
  final baseUrl = switch (currentSite) {
    Site.q1 => ApiEndPoints.siteQ1BaseUrl,
    Site.q3 => ApiEndPoints.siteQ3BaseUrl,
  };

  return ChopperClient(
    baseUrl: Uri.tryParse(baseUrl),
    services: _services,
    converter: const JsonConverter(),
    interceptors: [LoggingInterceptor(), AuthInterceptor()],
  );
}
