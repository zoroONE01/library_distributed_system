import 'package:library_distributed_app/core/extensions/ref_extension.dart';
import 'package:library_distributed_app/core/extensions/router_extension.dart';
import 'package:library_distributed_app/core/utils/secure_storage_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  Future<bool> build() async {
    final accessToken = await secureStorage.readAccessToken();
    return accessToken?.isNotEmpty ?? false;
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    ref.startLoading();
    await Future.delayed(const Duration(seconds: 3));
    secureStorage.writeAccessToken('mock_access_token');
    state = AsyncValue.data(true);
    ref.stopLoading();
    ref.router.replaceAll('/');
  }

  Future<void> logout() async {
    ref.startLoading();
    secureStorage.deleteAll();
    state = AsyncValue.data(false);
    ref.stopLoading();
    ref.router.replaceAll('/login');
  }
}
