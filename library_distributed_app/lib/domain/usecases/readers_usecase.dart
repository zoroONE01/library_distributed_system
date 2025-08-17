import 'dart:async';

import 'package:library_distributed_app/domain/entities/reader.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:library_distributed_app/domain/repositories/readers_repository.dart';
import 'package:library_distributed_app/domain/usecases/usecases.dart';
import 'package:result_dart/result_dart.dart';

// Using Dart record types for parameters
typedef GetReadersParams = ({int page, String? search});
typedef GetReadersWithStatsParams = ({int page, String? search});
typedef UpdateReaderParams = ({String readerId, ReaderEntity reader});

// FR8: Reader CRUD Use Cases (THUTHU only at their site)
// FR11: System-wide Reader Queries (QUANLY)
// =======================================================

/// Get readers with role-based access control
/// THUTHU: only their site, QUANLY: system-wide
class GetReadersUseCase
    extends
        UseCaseWithParams<
          (List<ReaderEntity>, PagingEntity),
          GetReadersParams
        > {
  const GetReadersUseCase(this._repository);
  final ReadersRepository _repository;

  @override
  Future<Result<(List<ReaderEntity>, PagingEntity)>> call(
    GetReadersParams params,
  ) {
    return _repository.getReaders(
      page: params.page,
      search: params.search,
    );
  }
}

/// Get reader by ID
class GetReaderByIdUseCase extends UseCaseWithParams<ReaderEntity, String> {
  const GetReaderByIdUseCase(this._repository);
  final ReadersRepository _repository;

  @override
  Future<Result<ReaderEntity>> call(String readerId) {
    if (readerId.isEmpty) {
      return Future.value(Failure(Exception('Reader ID cannot be empty')));
    }
    return _repository.getReaderById(readerId);
  }
}

/// FR8: Create new reader (THUTHU only at their site)
/// Automatically assigns registration site to THUTHU's branch
class CreateReaderUseCase
    extends UseCaseWithParams<ReaderEntity, ReaderEntity> {
  const CreateReaderUseCase(this._repository);
  final ReadersRepository _repository;

  @override
  Future<Result<ReaderEntity>> call(ReaderEntity reader) async {
    // Validate reader data
    if (reader.readerId.isEmpty) {
      return Failure(Exception('Reader ID cannot be empty'));
    }
    if (reader.fullName.isEmpty) {
      return Failure(Exception('Reader name cannot be empty'));
    }

    return _repository.createReader(reader);
  }
}

/// FR8: Update reader (THUTHU only at their site)
/// Cannot change registration site (fragmentation key)
class UpdateReaderUseCase
    extends UseCaseWithParams<ReaderEntity, UpdateReaderParams> {
  const UpdateReaderUseCase(this._repository);
  final ReadersRepository _repository;

  @override
  Future<Result<ReaderEntity>> call(UpdateReaderParams params) async {
    // Validate parameters
    if (params.readerId.isEmpty) {
      return Failure(Exception('Reader ID cannot be empty'));
    }
    if (params.reader.fullName.isEmpty) {
      return Failure(Exception('Reader name cannot be empty'));
    }

    return _repository.updateReader(params.readerId, params.reader);
  }
}

/// FR8: Delete reader (THUTHU only at their site)
/// Only allowed if reader has no active borrow records
class DeleteReaderUseCase extends VoidUseCaseWithParams<String> {
  const DeleteReaderUseCase(this._repository);
  final ReadersRepository _repository;

  @override
  Future<Result<String>> call(String readerId) async {
    if (readerId.isEmpty) {
      return failure('Reader ID cannot be empty');
    }

    final result = await _repository.deleteReader(readerId);
    return result.fold(
      (success) => this.success,
      (failure) => this.failure(failure),
    );
  }
}

/// FR11: Get readers with borrowing statistics (enhanced for managers)
/// Provides comprehensive view of reader activity across the system
class GetReadersWithStatsUseCase
    extends
        UseCaseWithParams<
          (List<ReaderWithStatsEntity>, PagingEntity),
          GetReadersWithStatsParams
        > {
  const GetReadersWithStatsUseCase(this._repository);
  final ReadersRepository _repository;

  @override
  Future<Result<(List<ReaderWithStatsEntity>, PagingEntity)>> call(
    GetReadersWithStatsParams params,
  ) {
    return _repository.getReadersWithStats(
      page: params.page,
      search: params.search,
    );
  }
}

/// FR11: Search readers system-wide (QUANLY)
/// Allows managers to find readers across all sites
class SearchReadersSystemWideUseCase
    extends UseCaseWithParams<List<ReaderEntity>, String> {
  const SearchReadersSystemWideUseCase(this._repository);
  final ReadersRepository _repository;

  @override
  Future<Result<List<ReaderEntity>>> call(String searchTerm) {
    if (searchTerm.isEmpty) {
      return Future.value(Failure(Exception('Search term cannot be empty')));
    }

    final trimmedSearch = searchTerm.trim();
    if (trimmedSearch.length < 2) {
      return Future.value(
        Failure(Exception('Search term must be at least 2 characters')),
      );
    }

    return _repository.searchReadersSystemWide(trimmedSearch);
  }
}

/// Get reader borrowing history (supports both local and system-wide queries)
class GetReaderBorrowingHistoryUseCase
    extends
        UseCaseWithParams<
          (List<ReaderWithStatsEntity>, PagingEntity),
          GetReadersWithStatsParams
        > {
  const GetReaderBorrowingHistoryUseCase(this._repository);
  final ReadersRepository _repository;

  @override
  Future<Result<(List<ReaderWithStatsEntity>, PagingEntity)>> call(
    GetReadersWithStatsParams params,
  ) {
    // This uses the same implementation as GetReadersWithStatsUseCase
    // but provides semantic clarity for borrowing history queries
    return _repository.getReadersWithStats(
      page: params.page,
      search: params.search,
    );
  }
}
