import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/api/api_client.dart';
import 'package:library_distributed_app/data/repositories/stats_repository.dart';
import 'package:library_distributed_app/data/services/manager_service.dart';
import 'package:library_distributed_app/data/services/stats_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:library_distributed_app/domain/entities/stats.dart';
import 'package:library_distributed_app/domain/entities/reader.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:result_dart/result_dart.dart';

part 'stats_repository.g.dart';

/// Repository interface for Statistics operations (FR6)
/// - FR6: Thống kê toàn hệ thống (QUANLY only)
abstract class StatsRepository {
  /// Get system-wide statistics (FR6 - QUANLY only)
  /// Performs distributed query across all sites
  Future<Result<SystemStatsResponseEntity>> getSystemStats();

  /// Get readers with borrowing statistics
  Future<Result<(List<ReaderWithStatsEntity>, PagingEntity)>>
  getReadersWithStats({int page = 0, int size = 20, String? search});

  /// Get site-specific statistics
  Future<Result<SiteStatsEntity>> getSiteStats();

  /// Get basic system statistics (books on loan count)
  Future<Result<SystemStatsEntity>> getBasicSystemStats();
}

@riverpod
StatsRepository statsRepository(Ref ref) {
  final statsService = ref.read(apiClientProvider).getService<StatsService>();
  final managerService = ref
      .read(apiClientProvider)
      .getService<ManagerService>();
  return StatsRepositoryImpl(statsService, managerService);
}
