import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
      builder: (context, child) => GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: _buildApp(child),
      ),
    );
  }

  Widget _buildApp(Widget? child) =>
      Stack(children: [if (child != null) child, const _AppLoading()]);
}

class _AppLoading extends HookConsumerWidget {
  const _AppLoading();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadingWidget = useMemoized(
      () => Positioned.fill(
        child: ColoredBox(
          color: context.surfaceColor.withValues(alpha: .5),
          child: const Center(child: CircularProgressIndicator.adaptive()),
        ),
      ),
    );
    final isLoading = ref.watch(appLoadingProvider);

    return isLoading ? loadingWidget : const SizedBox.shrink();
  }
}
