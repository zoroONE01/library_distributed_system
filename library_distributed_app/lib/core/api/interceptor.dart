import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:library_distributed_app/core/utils/logger.dart';
import 'package:library_distributed_app/core/utils/secure_storage_manager.dart';

/// Simple logging interceptor
class LoggingInterceptor implements Interceptor {
  const LoggingInterceptor();

  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(
    Chain<BodyType> chain,
  ) async {
    final request = chain.request;

    logger.d('🚀 ${request.method} ${request.url}');

    if (request.body != null) {
      logger.d('📤 Body: ${request.body}');
    }

    final response = await chain.proceed(request);

    final statusEmoji = response.isSuccessful ? '✅' : '❌';
    logger.d('$statusEmoji ${response.statusCode} ${request.url}');

    if (!response.isSuccessful) {
      logger.e('📥 Error: ${response.bodyString}');
    }

    return response;
  }
}

/// Simple authentication interceptor
class AuthInterceptor implements Interceptor {
  const AuthInterceptor();

  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(
    Chain<BodyType> chain,
  ) async {
    final token = await secureStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      final headers = Map<String, String>.from(chain.request.headers);
      headers['Authorization'] = 'Bearer $token';

      final request = chain.request.copyWith(headers: headers);
      return chain.proceed(request);
    }

    return chain.proceed(chain.request);
  }
}
