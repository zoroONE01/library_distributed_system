import 'dart:async';

import 'package:library_distributed_app/domain/entities/user_info.dart';
import 'package:library_distributed_app/domain/repositories/auth_repository.dart';
import 'package:library_distributed_app/domain/usecases/usecases.dart';
import 'package:result_dart/result_dart.dart';

typedef AuthLoginParams = ({String username, String password});

class AuthLoginUseCase extends VoidUseCaseWithParams<AuthLoginParams> {
  const AuthLoginUseCase({required AuthRepository authRepository})
    : _authRepository = authRepository;

  final AuthRepository _authRepository;

  @override
  Future<Result<String>> call(AuthLoginParams params) async {
    if (params.username.isEmpty || params.password.isEmpty) {
      return failure('Username and password must not be empty');
    }
    return _authRepository.login(
      username: params.username,
      password: params.password,
    );
  }
}

class AuthLogoutUseCase extends VoidUseCase {
  const AuthLogoutUseCase({required AuthRepository authRepository})
    : _authRepository = authRepository;

  final AuthRepository _authRepository;

  @override
  Future<Result<String>> call() {
    return _authRepository.logout();
  }
}

class AuthGetProfileUseCase extends UseCase<UserInfoEntity> {
  const AuthGetProfileUseCase({required AuthRepository authRepository})
    : _authRepository = authRepository;

  final AuthRepository _authRepository;

  @override
  Future<Result<UserInfoEntity>> call() {
    return _authRepository.getProfile();
  }
}
