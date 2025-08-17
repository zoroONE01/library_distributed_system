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

    // Always log response body, regardless of parse status or success
    try {
      final responseBody = response.bodyString;
      if (responseBody.isNotEmpty) {
        if (response.isSuccessful) {
          logger.d('📥 Response from ${request.url}: $responseBody');
        } else {
          logger.e('📥 Error from ${request.url}: $responseBody');
        }
      } else {
        logger.d('📥 Empty response body from ${request.url}');
      }
    } catch (e) {
      // If we can't get bodyString, try to get raw body
      logger.w('⚠️ Could not parse response body from ${request.url}: $e');
      try {
        final rawBody = response.body;
        logger.d('📥 Raw response from ${request.url}: $rawBody');
      } catch (rawError) {
        logger.e(
          '❌ Could not access raw response body from ${request.url}: $rawError',
        );
      }
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
      logger.d('🔐 Adding auth token to request: ${chain.request.url}');
      final headers = Map<String, String>.from(chain.request.headers);
      headers['Authorization'] = 'Bearer $token';

      final request = chain.request.copyWith(headers: headers);
      return chain.proceed(request);
    } else {
      logger.d('⚠️ No auth token found for request: ${chain.request.url}');
    }

    return chain.proceed(chain.request);
  }
}
