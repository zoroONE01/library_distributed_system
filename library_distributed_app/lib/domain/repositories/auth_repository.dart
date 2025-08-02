import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/api/api_client.dart';
import 'package:library_distributed_app/data/models/auth_info.dart';
import 'package:library_distributed_app/data/models/user_info.dart';
import 'package:library_distributed_app/data/repositories/auth_repository.dart';
import 'package:library_distributed_app/data/services/auth_service.dart';
import 'package:library_distributed_app/domain/entities/login_form.dart';
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

  Future<AuthInfoModel> login(LoginFormEntity entity);

  Future<void> logout();

  Future<UserInfoModel> getProfile();
}
