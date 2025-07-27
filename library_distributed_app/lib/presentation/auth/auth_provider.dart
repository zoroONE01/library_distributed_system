import 'package:library_distributed_app/core/extensions/ref_extension.dart';
import 'package:library_distributed_app/core/extensions/router_extension.dart';
import 'package:library_distributed_app/core/extensions/string_extension.dart';
import 'package:library_distributed_app/core/utils/secure_storage_manager.dart';
import 'package:library_distributed_app/domain/entities/login_form.dart';
import 'package:library_distributed_app/domain/repositories/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  Future<bool> build() async {
    final accessToken = await secureStorage.readAccessToken();
    return accessToken?.isNotEmpty ?? false;
  }

  Future<void> login(LoginFormEntity entity) async {
    try {
      ref.startLoading();

      final result = await ref.read(authRepositoryProvider).login(entity);

      if (result.accessToken.isNullOrEmpty) {
        throw Exception('Login failed: Result is null');
      }

      secureStorage.writeAccessToken(result.accessToken!);
      state = AsyncValue.data(true);
      ref.router.replaceAll('/');
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    } finally {
      ref.stopLoading();
    }
  }

  Future<void> logout() async {
    ref.startLoading();
    secureStorage.deleteAll();
    state = AsyncValue.data(false);
    ref.stopLoading();
    ref.router.replaceAll('/login');
  }
}
