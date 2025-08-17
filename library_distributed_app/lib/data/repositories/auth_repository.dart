import 'package:library_distributed_app/core/utils/logger.dart';
import 'package:library_distributed_app/core/utils/secure_storage_manager.dart';
import 'package:library_distributed_app/data/models/login_form.dart';
import 'package:library_distributed_app/domain/entities/user_info.dart';
import 'package:result_dart/result_dart.dart';

import '../../domain/repositories/auth_repository.dart';
import '../services/auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._service);
  final AuthService _service;

  @override
  Future<Result<String>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _service.login(
        LoginFormModel(username: username, password: password),
      );
      logger.i('Login response: ${response.body}');
      if (response.isSuccessful) {
        final accessToken = response.body!.accessToken;
        await secureStorage.writeAccessToken(accessToken);
        return const Success('OK');
      }
      final errorMessage = response.bodyString;
      logger.e('Login failed: $errorMessage');
      return Failure(Exception(errorMessage));
    } catch (e) {
      return Failure(Exception('Login error: $e'));
    }
  }

  @override
  Future<Result<UserInfoEntity>> getProfile() async {
    try {
      final response = await _service.getProfile();
      if (response.isSuccessful && response.body != null) {
        return Success(response.body!.toEntity());
      } else {
        final errorMessage = response.bodyString;
        logger.e('Get user profile failed: $errorMessage');
        return Failure(Exception('Get user profile failed: $errorMessage'));
      }
    } catch (e) {
      logger.e('Get user profile error: $e');
      return Failure(Exception('Get user profile error: $e'));
    }
  }

  @override
  Future<Result<String>> logout() async {
    try {
      await _service.logout();
      return const Success('Logout successful');
    } catch (e) {
      logger.e('Logout error: $e');
      return Failure(Exception('Logout error: $e'));
    }
  }
}
