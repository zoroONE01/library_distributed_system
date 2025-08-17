import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/api/api_client.dart';
import 'package:library_distributed_app/data/repositories/readers_repository.dart';
import 'package:library_distributed_app/data/services/manager_service.dart';
import 'package:library_distributed_app/data/services/readers_service.dart';
import 'package:library_distributed_app/data/services/stats_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:library_distributed_app/domain/entities/reader.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:result_dart/result_dart.dart';

part 'readers_repository.g.dart';

/// Repository interface for Reader operations (FR2, FR6)
/// - FR2: CRUD độc giả (THUTHU only at their site)
/// - FR6: Tra cứu độc giả toàn hệ thống (QUANLY)
abstract class ReadersRepository {
  /// Get paginated list of readers based on user role
  /// THUTHU: only their site, QUANLY: system-wide
  Future<Result<(List<ReaderEntity>, PagingEntity)>> getReaders({
    int page = 0,
    String? search,
  });

  /// Get reader by ID with role-based access control
  Future<Result<ReaderEntity>> getReaderById(String readerId);

  /// Create new reader (THUTHU only at their site)
  Future<Result<ReaderEntity>> createReader(ReaderEntity reader);

  /// Update reader (THUTHU only at their site)
  Future<Result<ReaderEntity>> updateReader(
    String readerId,
    ReaderEntity reader,
  );

  /// Delete reader (THUTHU only at their site)
  Future<Result<void>> deleteReader(String readerId);

  /// Get readers with statistics (for stats view)
  Future<Result<(List<ReaderWithStatsEntity>, PagingEntity)>>
  getReadersWithStats({int page = 0, String? search});

  /// Search readers system-wide (QUANLY only)
  Future<Result<List<ReaderEntity>>> searchReadersSystemWide(String searchTerm);
}

@riverpod
ReadersRepository readersRepository(Ref ref) {
  final readerService = ref
      .read(apiClientProvider)
      .getService<ReadersService>();
  final managerService = ref
      .read(apiClientProvider)
      .getService<ManagerService>();
  final statsService = ref.read(apiClientProvider).getService<StatsService>();
  return ReadersRepositoryImpl(readerService, statsService, managerService);
}
