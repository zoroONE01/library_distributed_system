import 'package:library_distributed_app/data/services/stats_service.dart';
import 'package:library_distributed_app/data/services/manager_service.dart';
import 'package:library_distributed_app/data/models/reader_with_stats.dart';
import 'package:library_distributed_app/data/models/list_response.dart';
import 'package:library_distributed_app/domain/entities/stats.dart';
import 'package:library_distributed_app/domain/entities/reader.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:library_distributed_app/domain/repositories/stats_repository.dart';
import 'package:library_distributed_app/core/constants/enums.dart';
import 'package:result_dart/result_dart.dart';

class StatsRepositoryImpl implements StatsRepository {
  final StatsService _statsService;
  final ManagerService _managerService;

  StatsRepositoryImpl(
    this._statsService,
    this._managerService,
  );

  @override
  Future<Result<SystemStatsResponseEntity>> getSystemStats() async {
    try {
      // Use manager service for system-wide statistics (FR6)
      final response = await _managerService.getSystemStats();
      
      if (response.isSuccessful && response.body != null) {
        final model = response.body!;
        
        return Success(SystemStatsResponseEntity(
          totalBooks: model.totalBooks,
          totalCopies: model.totalCopies,
          totalReaders: model.totalReaders,
          activeBorrows: model.activeBorrows,
          overdueBooks: model.overdueBooks,
          siteStats: model.siteStats.map((siteModel) => 
            SiteStatsEntity(
              siteId: siteModel.siteId,
              booksOnLoan: siteModel.booksOnLoan,
              totalBooks: siteModel.totalBooks,
              totalReaders: siteModel.totalReaders,
            )
          ).toList(),
          popularBooks: model.popularBooks.map((bookModel) => 
            // Convert to BookEntity - this will need proper mapping
            // depending on the actual model structure
            throw UnimplementedError('Book model mapping needed')
          ).toList(),
          generatedAt: model.generatedAt,
        ));
      }
      
      return Failure(Exception('Failed to get system stats: ${response.error}'));
    } catch (e) {
      return Failure(Exception('Error getting system stats: $e'));
    }
  }

  @override
  Future<Result<(List<ReaderWithStatsEntity>, PagingEntity)>> getReadersWithStats({
    int page = 0,
    int size = 20,
    String? search,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'size': size.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response = await _statsService.getReadersWithStats(params);
      
      if (response.isSuccessful && response.body != null) {
        final ListResponse<ReaderWithStatsModel> listResponse = response.body!;
        
        final readers = listResponse.items
            .map((model) => _mapReaderWithStatsModelToEntity(model))
            .toList();
        
        final paging = listResponse.paging.toEntity();
        
        return Success((readers, paging));
      }
      
      return Failure(Exception('Failed to get readers with stats: ${response.error}'));
    } catch (e) {
      return Failure(Exception('Error getting readers with stats: $e'));
    }
  }

  @override
  Future<Result<SiteStatsEntity>> getSiteStats() async {
    try {
      // This would need a specific site stats endpoint
      // For now, we'll use system stats and extract current site
      final systemStatsResult = await getSystemStats();
      
      return systemStatsResult.fold(
        (systemStats) {
          // Assuming we can determine current site somehow
          // This is a simplified implementation
          final currentSite = Site.q1; // This should come from user context
          
          final siteStats = systemStats.siteStats
              .where((stats) => stats.siteId == currentSite)
              .firstOrNull;
          
          return Success(siteStats ?? SiteStatsEntity(
            siteId: currentSite,
            booksOnLoan: 0,
            totalBooks: 0,
            totalReaders: 0,
          ));
        },
        (error) => Failure(Exception('Error getting site stats: $error')),
      );
    } catch (e) {
      return Failure(Exception('Error getting site stats: $e'));
    }
  }

  @override
  Future<Result<SystemStatsEntity>> getBasicSystemStats() async {
    try {
      // Use stats service for basic system statistics
      final response = await _statsService.getSystemStats();
      
      if (response.isSuccessful && response.body != null) {
        final model = response.body!;
        
        // Map the response to SystemStatsEntity
        // This will need to be adjusted based on actual response structure
        final Map<Site, SiteStatsEntity> statsBySite = {};
        
        // Convert site stats if available in the response
        // This is a placeholder - adjust based on actual model structure
        
        return Success(SystemStatsEntity(
          totalBooksOnLoan: model.activeBorrows,
          statsBySite: statsBySite,
        ));
      }
      
      return Failure(Exception('Failed to get basic system stats: ${response.error}'));
    } catch (e) {
      return Failure(Exception('Error getting basic system stats: $e'));
    }
  }

  // Helper methods for mapping
  ReaderWithStatsEntity _mapReaderWithStatsModelToEntity(ReaderWithStatsModel model) {
    return ReaderWithStatsEntity(
      readerId: model.readerId,
      fullName: model.fullName,
      registrationSite: model.registrationSite,
      totalBorrowed: model.totalBorrowed,
      currentBorrowed: model.currentBorrowed,
      overdueBooks: model.overdueBooks,
      lastBorrowDate: model.lastBorrowDate,
    );
  }
}