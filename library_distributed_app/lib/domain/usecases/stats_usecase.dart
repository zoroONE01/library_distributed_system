import 'dart:async';

import 'package:library_distributed_app/domain/entities/stats.dart';
import 'package:library_distributed_app/domain/entities/reader.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:library_distributed_app/domain/repositories/stats_repository.dart';
import 'package:library_distributed_app/domain/usecases/usecases.dart';
import 'package:result_dart/result_dart.dart';

// Using Dart record types for parameters
typedef GetStatsReadersWithStatsParams = ({int page, int size, String? search});

// FR6: Statistics Use Cases (System-wide for QUANLY)
// ===================================================

/// FR6: Get system-wide statistics (distributed query)
/// This implements the requirement for managers to view statistics across all sites
class GetSystemStatsUseCase extends UseCase<SystemStatsResponseEntity> {
  const GetSystemStatsUseCase(this._repository);
  final StatsRepository _repository;

  @override
  Future<Result<SystemStatsResponseEntity>> call() {
    return _repository.getSystemStats();
  }
}

/// Get detailed site statistics breakdown
class GetSiteStatsUseCase extends UseCase<List<SiteStatsEntity>> {
  const GetSiteStatsUseCase(this._repository);
  final StatsRepository _repository;

  @override
  Future<Result<List<SiteStatsEntity>>> call() async {
    final result = await _repository.getSystemStats();

    return result.fold(
      (systemStats) => Success(systemStats.siteStats),
      (failure) => Failure(failure),
    );
  }
}

/// Get readers with comprehensive statistics
class GetReadersWithStatisticsUseCase
    extends
        UseCaseWithParams<
          (List<ReaderWithStatsEntity>, PagingEntity),
          GetStatsReadersWithStatsParams
        > {
  const GetReadersWithStatisticsUseCase(this._repository);
  final StatsRepository _repository;

  @override
  Future<Result<(List<ReaderWithStatsEntity>, PagingEntity)>> call(
    GetStatsReadersWithStatsParams params,
  ) {
    return _repository.getReadersWithStats(
      page: params.page,
      size: params.size,
      search: params.search,
    );
  }
}

/// Get popular books statistics (most borrowed books)
class GetPopularBooksUseCase extends UseCase<List<Object>> {
  const GetPopularBooksUseCase(this._repository);
  final StatsRepository _repository;

  @override
  Future<Result<List<Object>>> call() async {
    final result = await _repository.getSystemStats();

    return result.fold(
      (systemStats) => Success(systemStats.popularBooks),
      (failure) => Failure(failure),
    );
  }
}

/// Get borrowing trends and analytics
class GetBorrowingTrendsUseCase extends UseCase<Map<String, dynamic>> {
  const GetBorrowingTrendsUseCase(this._repository);
  final StatsRepository _repository;

  @override
  Future<Result<Map<String, dynamic>>> call() async {
    final result = await _repository.getSystemStats();

    return result.fold((systemStats) {
      // Extract borrowing trends from system stats
      final trends = <String, dynamic>{
        'totalBooks': systemStats.totalBooks,
        'totalCopies': systemStats.totalCopies,
        'totalReaders': systemStats.totalReaders,
        'activeBorrows': systemStats.activeBorrows,
        'overdueBooks': systemStats.overdueBooks,
        'borrowRate': systemStats.totalCopies > 0
            ? (systemStats.activeBorrows / systemStats.totalCopies * 100)
                  .toStringAsFixed(2)
            : '0.00',
        'overdueRate': systemStats.activeBorrows > 0
            ? (systemStats.overdueBooks / systemStats.activeBorrows * 100)
                  .toStringAsFixed(2)
            : '0.00',
        'generatedAt': systemStats.generatedAt,
      };
      return Success(trends);
    }, (failure) => Failure(failure));
  }
}

/// Get real-time system health metrics
class GetSystemHealthUseCase extends UseCase<Map<String, dynamic>> {
  const GetSystemHealthUseCase(this._repository);
  final StatsRepository _repository;

  @override
  Future<Result<Map<String, dynamic>>> call() async {
    final result = await _repository.getSystemStats();

    return result.fold((systemStats) {
      // Calculate system health indicators
      final health = <String, dynamic>{
        'totalSites': systemStats.siteStats.length,
        'activeSites':
            systemStats.siteStats.length, // All sites that returned data
        'systemLoad': systemStats.activeBorrows,
        'capacity': systemStats.totalCopies,
        'utilizationRate': systemStats.totalCopies > 0
            ? (systemStats.activeBorrows / systemStats.totalCopies * 100)
                  .toStringAsFixed(2)
            : '0.00',
        'healthStatus':
            systemStats.overdueBooks < (systemStats.activeBorrows * 0.1)
            ? 'Good'
            : systemStats.overdueBooks < (systemStats.activeBorrows * 0.2)
            ? 'Warning'
            : 'Critical',
        'lastUpdated': systemStats.generatedAt,
      };
      return Success(health);
    }, (failure) => Failure(failure));
  }
}

/// Generate comprehensive system report
class GenerateSystemReportUseCase extends UseCase<Map<String, dynamic>> {
  const GenerateSystemReportUseCase(this._repository);
  final StatsRepository _repository;

  @override
  Future<Result<Map<String, dynamic>>> call() async {
    final result = await _repository.getSystemStats();

    return result.fold((systemStats) {
      // Create comprehensive report
      final report = <String, dynamic>{
        'summary': {
          'totalBooks': systemStats.totalBooks,
          'totalCopies': systemStats.totalCopies,
          'totalReaders': systemStats.totalReaders,
          'activeBorrows': systemStats.activeBorrows,
          'overdueBooks': systemStats.overdueBooks,
        },
        'siteBreakdown': systemStats.siteStats
            .map(
              (site) => {
                'siteId': site.siteId.name,
                'booksOnLoan': site.booksOnLoan,
                'totalBooks': site.totalBooks,
                'totalReaders': site.totalReaders,
                'utilizationRate': site.totalBooks > 0
                    ? (site.booksOnLoan / site.totalBooks * 100)
                          .toStringAsFixed(2)
                    : '0.00',
              },
            )
            .toList(),
        'popularBooks': systemStats.popularBooks
            .take(10)
            .map(
              (book) => {
                'isbn': book.isbn,
                'title': book.title,
                'author': book.author,
              },
            )
            .toList(),
        'metrics': {
          'borrowRate': systemStats.totalCopies > 0
              ? (systemStats.activeBorrows / systemStats.totalCopies * 100)
                    .toStringAsFixed(2)
              : '0.00',
          'overdueRate': systemStats.activeBorrows > 0
              ? (systemStats.overdueBooks / systemStats.activeBorrows * 100)
                    .toStringAsFixed(2)
              : '0.00',
        },
        'generatedAt': systemStats.generatedAt,
      };
      return Success(report);
    }, (failure) => Failure(failure));
  }
}

/// Quick stats for dashboard widgets
class GetDashboardStatsUseCase extends UseCase<Map<String, int>> {
  const GetDashboardStatsUseCase(this._repository);
  final StatsRepository _repository;

  @override
  Future<Result<Map<String, int>>> call() async {
    final result = await _repository.getSystemStats();

    return result.fold((systemStats) {
      final dashboardStats = <String, int>{
        'totalBooks': systemStats.totalBooks,
        'totalCopies': systemStats.totalCopies,
        'totalReaders': systemStats.totalReaders,
        'activeBorrows': systemStats.activeBorrows,
        'overdueBooks': systemStats.overdueBooks,
        'availableCopies': systemStats.totalCopies - systemStats.activeBorrows,
      };
      return Success(dashboardStats);
    }, (failure) => Failure(failure));
  }
}
