import 'package:chopper/chopper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/api/interceptor.dart';
import 'package:library_distributed_app/data/models/auth_info.dart';
import 'package:library_distributed_app/data/models/book.dart';
import 'package:library_distributed_app/data/models/book_copies.dart';
import 'package:library_distributed_app/data/models/book_copy.dart';
import 'package:library_distributed_app/data/models/book_search_result.dart';
import 'package:library_distributed_app/data/models/books.dart';
import 'package:library_distributed_app/data/models/borrow_record.dart';
import 'package:library_distributed_app/data/models/borrow_record_with_details.dart';
import 'package:library_distributed_app/data/models/borrow_records.dart';
import 'package:library_distributed_app/data/models/create_borrow_request.dart';
import 'package:library_distributed_app/data/models/login_form.dart';
import 'package:library_distributed_app/data/models/paging.dart';
import 'package:library_distributed_app/data/models/reader.dart';
import 'package:library_distributed_app/data/models/reader_with_stats.dart';
import 'package:library_distributed_app/data/models/readers.dart';
import 'package:library_distributed_app/data/models/return_book_request.dart';
import 'package:library_distributed_app/data/models/site_stats.dart';
import 'package:library_distributed_app/data/models/system_stats.dart';
import 'package:library_distributed_app/data/models/system_stats_response.dart';
import 'package:library_distributed_app/data/models/transfer_book_request.dart';
import 'package:library_distributed_app/data/models/transfer_book_response.dart';
import 'package:library_distributed_app/data/models/chi_nhanh.dart';
import 'package:library_distributed_app/data/models/user_info.dart';
import 'package:library_distributed_app/data/services/auth_service.dart';
import 'package:library_distributed_app/data/services/book_copies_service.dart';
import 'package:library_distributed_app/data/services/books_service.dart';
import 'package:library_distributed_app/data/services/borrow_service.dart';
import 'package:library_distributed_app/data/services/manager_service.dart';
import 'package:library_distributed_app/data/services/readers_service.dart';
import 'package:library_distributed_app/data/services/stats_service.dart';
import 'package:library_distributed_app/core/utils/json_serializable_converter.dart';
import 'package:library_distributed_app/presentation/app/app_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/api_end_points.dart';
import '../constants/enums.dart';

part 'api_client.g.dart';

const _interceptors = [AuthInterceptor(), LoggingInterceptor()];

const _converter = JsonSerializableConverter({
  // Auth models
  AuthInfoModel: AuthInfoModel.fromJson,
  UserInfoModel: UserInfoModel.fromJson,
  LoginFormModel: LoginFormModel.fromJson,

  // Book models
  BookModel: BookModel.fromJson,
  BooksModel: BooksModel.fromJson,
  BookCopyModel: BookCopyModel.fromJson,
  BookCopiesModel: BookCopiesModel.fromJson,
  BookSearchResultModel: BookSearchResultModel.fromJson,

  // Reader models
  ReaderModel: ReaderModel.fromJson,
  ReadersModel: ReadersModel.fromJson,
  ReaderWithStatsModel: ReaderWithStatsModel.fromJson,

  // Borrow models
  BorrowRecordModel: BorrowRecordModel.fromJson,
  BorrowRecordWithDetailsModel: BorrowRecordWithDetailsModel.fromJson,
  BorrowRecordsModel: BorrowRecordsModel.fromJson,
  CreateBorrowRequestModel: CreateBorrowRequestModel.fromJson,
  ReturnBookRequestModel: ReturnBookRequestModel.fromJson,

  // Stats models
  SiteStatsModel: SiteStatsModel.fromJson,
  SystemStatsModel: SystemStatsModel.fromJson,
  SystemStatsResponseModel: SystemStatsResponseModel.fromJson,

  // Branch models
  ChiNhanhModel: ChiNhanhModel.fromJson,

  // Transfer models
  TransferBookRequestModel: TransferBookRequestModel.fromJson,
  TransferBookResponseModel: TransferBookResponseModel.fromJson,

  // Common models
  PagingModel: PagingModel.fromJson,
  // Note: ListResponse<T> is handled automatically by Chopper for generic types
});

final _services = [
  AuthService.create(),
  BooksService.create(),
  BookCopiesService.create(),
  BorrowService.create(),
  ReadersService.create(),
  ManagerService.create(),
  StatsService.create(),
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
