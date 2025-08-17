import 'package:library_distributed_app/data/services/readers_service.dart';
import 'package:library_distributed_app/data/services/stats_service.dart';
import 'package:library_distributed_app/data/services/manager_service.dart';
import 'package:library_distributed_app/core/constants/common.dart';
import 'package:library_distributed_app/data/models/reader.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:library_distributed_app/domain/entities/reader.dart';
import 'package:library_distributed_app/domain/repositories/readers_repository.dart';
import 'package:library_distributed_app/core/constants/enums.dart';
import 'package:result_dart/result_dart.dart';

class ReadersRepositoryImpl implements ReadersRepository {
  final ReadersService _readersService;
  final StatsService _statsService;
  final ManagerService _managerService;

  const ReadersRepositoryImpl(
    this._readersService,
    this._statsService,
    this._managerService,
  );

  @override
  Future<Result<(List<ReaderEntity>, PagingEntity)>> getReaders({
    int page = 0,
    String? search,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'size': kPaginationPageSize.toString(),
      };

      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }

      final response = await _readersService.getList(params);

      if (response.isSuccessful && response.body != null) {
        final readersModel = response.body!;

        final readers = readersModel.items
            .map((model) => _mapReaderModelToEntity(model))
            .toList();

        final paging = PagingEntity(
          currentPage: readersModel.paging.page,
          pageSize: readersModel.paging.size,
          totalPages: readersModel.paging.totalPages ?? 1,
        );

        return Success((readers, paging));
      }

      return Failure(Exception('Failed to get readers: ${response.error}'));
    } catch (e) {
      return Failure(Exception('Error getting readers: $e'));
    }
  }

  @override
  Future<Result<ReaderEntity>> getReaderById(String readerId) async {
    try {
      final response = await _readersService.get(readerId);

      if (response.isSuccessful && response.body != null) {
        return Success(_mapReaderModelToEntity(response.body!));
      }

      return Failure(Exception('Reader not found'));
    } catch (e) {
      return Failure(Exception('Error getting reader by ID: $e'));
    }
  }

  @override
  Future<Result<ReaderEntity>> createReader(ReaderEntity reader) async {
    try {
      final model = _mapReaderEntityToModel(reader);
      final response = await _readersService.createNew(model);

      if (response.isSuccessful && response.body != null) {
        return Success(_mapReaderModelToEntity(response.body!));
      }

      return Failure(Exception('Failed to create reader: ${response.error}'));
    } catch (e) {
      return Failure(Exception('Error creating reader: $e'));
    }
  }

  @override
  Future<Result<ReaderEntity>> updateReader(
    String readerId,
    ReaderEntity reader,
  ) async {
    try {
      final model = _mapReaderEntityToModel(reader);
      final response = await _readersService.update(readerId, model);

      if (response.isSuccessful && response.body != null) {
        return Success(_mapReaderModelToEntity(response.body!));
      }

      return Failure(Exception('Failed to update reader: ${response.error}'));
    } catch (e) {
      return Failure(Exception('Error updating reader: $e'));
    }
  }

  @override
  Future<Result<void>> deleteReader(String readerId) async {
    try {
      final response = await _readersService.delete(readerId);

      if (response.isSuccessful) {
        return const Success(unit);
      }

      return Failure(Exception('Failed to delete reader: ${response.error}'));
    } catch (e) {
      return Failure(Exception('Error deleting reader: $e'));
    }
  }

  @override
  Future<Result<(List<ReaderWithStatsEntity>, PagingEntity)>>
  getReadersWithStats({
    int page = 0,
    int size = kPaginationPageSize,
    String? search,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }

      final response = await _statsService.getReadersWithStats(params);

      if (response.isSuccessful && response.body != null) {
        final readersWithStatsModel = response.body!;

        final readers = readersWithStatsModel.items
            .map((model) => _mapReaderWithStatsModelToEntity(model))
            .toList();

        final paging = PagingEntity(
          currentPage: readersWithStatsModel.paging.page,
          pageSize: readersWithStatsModel.paging.size,
          totalPages: readersWithStatsModel.paging.totalPages ?? 1,
        );

        return Success((readers, paging));
      }

      return Failure(
        Exception('Failed to get readers with stats: ${response.error}'),
      );
    } catch (e) {
      return Failure(Exception('Error getting readers with stats: $e'));
    }
  }

  @override
  Future<Result<List<ReaderEntity>>> searchReadersSystemWide(
    String searchTerm,
  ) async {
    try {
      final response = await _managerService.getAllReaders(searchTerm);

      if (response.isSuccessful && response.body != null) {
        final readers = response.body!
            .map((model) => _mapReaderModelToEntity(model))
            .toList();

        return Success(readers);
      }

      return Failure(
        Exception('Failed to search readers system-wide: ${response.error}'),
      );
    } catch (e) {
      return Failure(Exception('Error searching readers system-wide: $e'));
    }
  }

  // Helper methods for mapping
  ReaderEntity _mapReaderModelToEntity(ReaderModel model) {
    return ReaderEntity(
      readerId: model.readerId,
      fullName: model.fullName,
      registrationSite: model.registrationSite,
    );
  }

  ReaderModel _mapReaderEntityToModel(ReaderEntity entity) {
    return ReaderModel(
      readerId: entity.readerId,
      fullName: entity.fullName,
      registrationSite: entity.registrationSite,
    );
  }

  ReaderWithStatsEntity _mapReaderWithStatsModelToEntity(dynamic model) {
    return ReaderWithStatsEntity(
      readerId: model.readerId ?? '',
      fullName: model.fullName ?? '',
      registrationSite: model.registrationSite ?? Site.q1,
      totalBorrowed: model.totalBorrowed ?? 0,
      currentBorrowed: model.currentBorrowed ?? 0,
      overdueBooks: model.overdueBooks ?? 0,
      lastBorrowDate: model.lastBorrowDate,
    );
  }
}
