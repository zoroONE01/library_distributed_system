import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/api/api_client.dart';
import 'package:library_distributed_app/data/repositories/auth_repository.dart';
import 'package:library_distributed_app/data/services/auth_service.dart';
import 'package:library_distributed_app/domain/entities/user_info.dart';
import 'package:result_dart/result_dart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    ref.read(apiClientProvider).getService<AuthService>(),
  );
}

abstract class AuthRepository {
  const AuthRepository();

  Future<Result<String>> login({
    required String username,
    required String password,
  });

  Future<Result<String>> logout();

  Future<Result<UserInfoEntity>> getProfile();
}
