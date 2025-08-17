import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/domain/entities/reader.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:library_distributed_app/domain/repositories/readers_repository.dart';
import 'package:library_distributed_app/domain/usecases/readers_usecase.dart';
import 'package:library_distributed_app/presentation/auth/auth_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'readers_provider.g.dart';

/// Main provider for readers state management
/// Implements role-based access control for FR8 and FR11 requirements
@riverpod
class Readers extends _$Readers {
  @override
  Future<ReadersEntity> build() async {
    // Check authentication first
    final isAuthenticated = await ref.watch(authProvider.future);
    if (!isAuthenticated) {
      throw Exception('Authentication required');
    }

    // Fetch initial data directly and return result
    return await _fetchDataDirect();
  }

  /// Fetch readers and return result directly (for build method)
  Future<ReadersEntity> _fetchDataDirect([int page = 0, String? search]) async {
    try {
      final useCase = GetReadersUseCase(ref.read(readersRepositoryProvider));
      final result = await useCase.call((page: page, search: search));

      return result.fold(
        (success) {
          final (readers, paging) = success;
          return ReadersEntity(items: readers, paging: paging);
        },
        (failure) {
          throw failure;
        },
      );
    } catch (e) {
      throw Exception('Error getting readers: $e');
    }
  }

  /// Fetch readers with pagination and search
  /// FR8: THUTHU only sees their site, QUANLY sees system-wide
  Future<void> fetchData([int page = 0, String? search]) async {
    try {
      state = const AsyncValue.loading();

      final result = await _fetchDataDirect(page, search);
      state = AsyncValue.data(result);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    final currentState = state.valueOrNull;
    final currentPage = currentState?.paging.currentPage ?? 0;
    final currentSearch = ref.read(readersSearchProvider);
    await fetchData(currentPage, currentSearch.isEmpty ? null : currentSearch);
  }
}

/// Entity to match the pattern used in books
class ReadersEntity {
  final List<ReaderEntity> items;
  final PagingEntity paging;

  const ReadersEntity({
    this.items = const [],
    this.paging = const PagingEntity(),
  });
}

/// Search state provider for readers
final readersSearchProvider = StateProvider<String>((ref) => '');

/// Get reader by ID
@riverpod
Future<ReaderEntity> readerById(Ref ref, String readerId) async {
  final useCase = GetReaderByIdUseCase(ref.read(readersRepositoryProvider));
  final result = await useCase.call(readerId);
  ref.keepAlive();

  return result.fold((reader) => reader, (failure) => throw failure);
}

/// Get readers with statistics (for enhanced view)
@riverpod
Future<(List<ReaderWithStatsEntity>, PagingEntity)> readersWithStats(
  Ref ref,
  int page,
  String? search,
) async {
  final useCase = GetReadersWithStatsUseCase(ref.read(readersRepositoryProvider));
  final result = await useCase.call((page: page, search: search));
  ref.keepAlive();

  return result.fold((success) => success, (failure) => throw failure);
}

/// FR11: Search readers system-wide (QUANLY only)
@riverpod
Future<List<ReaderEntity>> searchReadersSystemWide(
  Ref ref,
  String searchTerm,
) async {
  final useCase = SearchReadersSystemWideUseCase(ref.read(readersRepositoryProvider));
  final result = await useCase.call(searchTerm);
  ref.keepAlive();

  return result.fold(
    (readers) => readers,
    (failure) => throw failure,
  );
}

/// FR8: Create new reader (THUTHU only at their site)
@riverpod
Future<void> createReader(Ref ref, ReaderEntity reader) async {
  final useCase = CreateReaderUseCase(ref.read(readersRepositoryProvider));
  final result = await useCase.call(reader);
  ref.keepAlive();

  result.fold(
    (success) {
      ref.invalidate(readersProvider);
    },
    (failure) {
      throw failure;
    },
  );
}

/// FR8: Update reader (THUTHU only at their site)
@riverpod
Future<void> updateReader(
  Ref ref,
  ({String readerId, ReaderEntity reader}) params,
) async {
  final useCase = UpdateReaderUseCase(ref.read(readersRepositoryProvider));
  final result = await useCase.call(params);
  ref.keepAlive();

  result.fold(
    (success) {
      ref.invalidate(readersProvider);
    },
    (failure) {
      throw failure;
    },
  );
}

/// FR8: Delete reader (THUTHU only at their site)
@riverpod
Future<void> deleteReader(Ref ref, String readerId) async {
  final useCase = DeleteReaderUseCase(ref.read(readersRepositoryProvider));
  final result = await useCase.call(readerId);
  ref.keepAlive();

  result.fold(
    (success) {
      ref.invalidate(readersProvider);
    },
    (failure) {
      throw failure;
    },
  );
}