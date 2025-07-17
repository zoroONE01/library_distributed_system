library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:library_distributed_app/core/utils/logger.dart';
import 'package:library_distributed_app/presentation/auth/login_page.dart';
import 'package:library_distributed_app/presentation/home/home_page.dart';

part 'router.g.dart';
part 'routes.dart';
part 'route_observer.dart';

final appRouterProvider = Provider.autoDispose(
  (ref) => GoRouter(
    routes: $appRoutes,
    initialLocation: '/',
    observers: [AppRouteObserver(ref)],
  ),
);
