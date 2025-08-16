import 'package:chopper/chopper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/api/interceptor.dart';
import 'package:library_distributed_app/data/models/auth_info.dart';
import 'package:library_distributed_app/data/models/book.dart';
import 'package:library_distributed_app/data/models/book_copies.dart';
import 'package:library_distributed_app/data/models/book_copy.dart';
import 'package:library_distributed_app/data/models/books.dart';
import 'package:library_distributed_app/data/models/paging.dart';
import 'package:library_distributed_app/data/models/user_info.dart';
import 'package:library_distributed_app/data/services/auth_service.dart';
import 'package:library_distributed_app/core/utils/json_serializable_converter.dart';
import 'package:library_distributed_app/data/services/book_copies_service.dart';
import 'package:library_distributed_app/data/services/books_service.dart';
import 'package:library_distributed_app/presentation/app/app_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/api_end_points.dart';
import '../constants/enums.dart';

part 'api_client.g.dart';

const _interceptors = [AuthInterceptor(), LoggingInterceptor()];

const _converter = JsonSerializableConverter({
  AuthInfoModel: AuthInfoModel.fromJson,
  UserInfoModel: UserInfoModel.fromJson,
  PagingModel: PagingModel.fromJson,
  BooksModel: BooksModel.fromJson,
  BookModel: BookModel.fromJson,
  BookCopiesModel: BookCopiesModel.fromJson,
  BookCopyModel: BookCopyModel.fromJson,
});

final _services = [
  AuthService.create(),
  BooksService.create(),
  BookCopiesService.create(),
];

@Riverpod(keepAlive: true)
ChopperClient apiClient(Ref ref) {
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

@riverpod
ChopperClient apiClientCoordinator(Ref ref) {
  final client = ChopperClient(
    baseUrl: Uri.tryParse(ApiEndPoints.coordinatorBaseUrl),
    services: _services,
    converter: _converter,
    interceptors: _interceptors,
  );

  ref.onDispose(client.dispose);
  return client;
}
