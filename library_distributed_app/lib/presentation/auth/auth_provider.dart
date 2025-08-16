import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/extensions/ref_extension.dart';
import 'package:library_distributed_app/core/extensions/router_extension.dart';
import 'package:library_distributed_app/core/extensions/string_extension.dart';
import 'package:library_distributed_app/core/utils/secure_storage_manager.dart';
import 'package:library_distributed_app/domain/entities/login_form.dart';
import 'package:library_distributed_app/domain/entities/user_info.dart';
import 'package:library_distributed_app/domain/repositories/auth_repository.dart';
import 'package:library_distributed_app/domain/usecases/auth_usecase.dart';
import 'package:result_dart/result_dart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  Future<bool> build() async {
    final accessToken = await secureStorage.readAccessToken();
    return !accessToken.isNullOrEmpty;
  }

  void login(LoginFormEntity entity) {
    ref.startLoading();
    AuthLoginUseCase(authRepository: ref.read(authRepositoryProvider))
        .call(entity)
        .then(
          (value) => value.fold(
            (success) {
              state = const AsyncValue.data(true);
              ref.router.replaceAll('/');
            },
            (error) {
              secureStorage.deleteAll();
              state = AsyncValue.error(error, StackTrace.current);
            },
          ),
        )
        .whenComplete(ref.stopLoading);
  }

  void logout() {
    ref.startLoading();
    AuthLogoutUseCase(authRepository: ref.read(authRepositoryProvider))
        .call()
        .then(
          (value) => value.fold(
            (success) {
              secureStorage.deleteAll();
              state = const AsyncValue.data(false);
              ref.invalidate(getUserInfoProvider);
              ref.router.replaceAll('/login');
            },
            (error) {
              state = AsyncValue.error(error, StackTrace.current);
            },
          ),
        )
        .whenComplete(ref.stopLoading);
  }
}

@riverpod
Future<UserInfoEntity> getUserInfo(Ref ref) async {
  final userInfo =
      await AuthGetProfileUseCase(
        authRepository: ref.read(authRepositoryProvider),
      ).call().fold((success) => success, (error) {
        throw Exception(error);
      });
  ref.keepAlive();
  return userInfo;
}
