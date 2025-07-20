library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:library_distributed_app/core/utils/logger.dart';
import 'package:library_distributed_app/presentation/auth/auth_provider.dart';
import 'package:library_distributed_app/presentation/auth/login_page.dart';
import 'package:library_distributed_app/presentation/books/book_list_page.dart';
import 'package:library_distributed_app/presentation/borrowing/borrow_page.dart';
import 'package:library_distributed_app/presentation/branches/branchs_page.dart';
import 'package:library_distributed_app/presentation/home/home_page.dart';
import 'package:library_distributed_app/presentation/main/main_page.dart';
import 'package:library_distributed_app/presentation/readers/reader_list_page.dart';

part 'router.g.dart';
part 'routes.dart';
part 'route_observer.dart';

final appRouterProvider = Provider(
  (ref) => GoRouter(
    routes: $appRoutes,
    initialLocation: '/books',
    observers: [AppRouteObserver(ref)],
    redirect: (context, state) async {
      final loggedIn = await ref.read(authProvider.future);
      if (loggedIn) return null;
      if (state.path == '/login') {
        return null;
      }
      return '/login';
    },
  ),
);
