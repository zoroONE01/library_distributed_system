import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension RouterBuildContextExtension on BuildContext {
  Future<T?> replaceAll<T extends Object?>(
    String path, {
    Object? extra,
  }) async {
    return GoRouter.of(this).replaceAll<T>(
      path,
      extra: extra,
    );
  }
}

extension RouterGoRouterStateExtension on GoRouter {
  Future<T?> replaceAll<T extends Object?>(
    String path, {
    Object? extra,
  }) async {
    return pushReplacement<T>(
      path,
      extra: extra,
    );
  }
}
