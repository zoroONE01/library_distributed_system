import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:library_distributed_app/presentation/app/app_provider.dart';
import 'package:library_distributed_app/router/router.dart';

extension RefExtension on Ref {
  void startLoading() {
    read(appLoadingProvider.notifier).startLoading();
  }

  void stopLoading() {
    read(appLoadingProvider.notifier).stopLoading();
  }


  GoRouter get router => read(appRouterProvider);
}
