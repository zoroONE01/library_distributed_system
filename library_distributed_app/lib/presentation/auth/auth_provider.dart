import 'package:library_distributed_app/core/extensions/ref_extension.dart';
import 'package:library_distributed_app/core/extensions/router_extension.dart';
import 'package:library_distributed_app/core/extensions/string_extension.dart';
import 'package:library_distributed_app/core/utils/secure_storage_manager.dart';
import 'package:library_distributed_app/data/models/user_info.dart';
import 'package:library_distributed_app/domain/entities/login_form.dart';
import 'package:library_distributed_app/domain/repositories/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  UserInfoModel? userInfo;

  @override
  Future<bool> build() async {
    final accessToken = await secureStorage.readAccessToken();
    final isLoggedIn = accessToken?.isNotEmpty ?? false;
    if (isLoggedIn) {
      await getProfile();
    }
    return isLoggedIn;
  }

  Future<void> login(LoginFormEntity entity) async {
    try {
      ref.startLoading();

      final result = await ref.read(authRepositoryProvider).login(entity);

      if (result.accessToken.isNullOrEmpty) {
        throw Exception('Login failed: Result is null');
      }

      await secureStorage.writeAccessToken(result.accessToken!);

      await _getProfile();

      state = AsyncValue.data(true);

      ref.router.replaceAll('/');
    } catch (e, stackTrace) {
      userInfo = null;
      secureStorage.deleteAll();
      state = AsyncValue.error(e, stackTrace);
    } finally {
      ref.stopLoading();
    }
  }

  Future<void> _getProfile() async {
    userInfo = await ref.read(authRepositoryProvider).getProfile();
  }

  Future<void> getProfile() async {
    try {
      ref.startLoading();
      await _getProfile();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    } finally {
      ref.stopLoading();
    }
  }

  Future<void> logout() async {
    try {
      ref.startLoading();
      await ref.read(authRepositoryProvider).logout();
      userInfo = null;
      secureStorage.deleteAll();
      state = AsyncValue.data(false);
      ref.router.replaceAll('/login');
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    } finally {
      ref.stopLoading();
    }
  }
}
