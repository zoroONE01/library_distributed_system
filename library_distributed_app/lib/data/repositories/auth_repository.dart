import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/utils/logger.dart';

import '../../core/api/api_client.dart';
import '../../domain/entities/login_form.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_info.dart';
import '../models/user_info.dart';
import '../services/auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this.ref);
  final Ref ref;

  AuthService get _authService =>
      ref.read(apiClientProviderProvider).getService<AuthService>();

  @override
  Future<AuthInfoModel> login(LoginFormEntity entity) async {
    try {
      final response = await _authService.login(entity);


      logger.i('Login response: ${response.body}');
      if (response.isSuccessful && response.body != null) {
        final authInfo = response.body!;

        return authInfo;
      } else {
        final errorMessage = response.bodyString;
        logger.e('Login failed: $errorMessage');
        throw Exception('Login failed: $errorMessage');
      }
    } catch (e) {
      logger.e('Login error: $e');
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (e) {
      logger.e('Logout error: $e');
      // Don't rethrow logout errors, just log them
    }
  }

  @override
  Future<UserInfoModel> getProfile() async {
    try {
      final response = await _authService.getProfile();

      if (response.isSuccessful && response.body != null) {
        return response.body!;
      } else {
        final errorMessage = response.bodyString;
        logger.e('Get user profile failed: $errorMessage');
        throw Exception('Get user profile failed: $errorMessage');
      }
    } catch (e) {
      logger.e('Get user profile error: $e');
      rethrow;
    }
  }
}
