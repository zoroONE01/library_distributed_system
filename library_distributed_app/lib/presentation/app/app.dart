import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/core/theme/app_theme.dart';
import 'package:library_distributed_app/core/theme/app_theme_mode.dart';
import 'package:library_distributed_app/presentation/app/app_provider.dart';
import 'package:library_distributed_app/router/router.dart';

class App extends HookConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.read(appRouterProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp.router(
      title: 'Library Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            Consumer(
              builder: (context, ref, child) {
                final isLoading = ref.watch(appLoadingProvider);
                return isLoading ? child! : const SizedBox.shrink();
              },
              child: Positioned.fill(
                child: ColoredBox(
                  color: context.surfaceColor.withValues(alpha: .5),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
