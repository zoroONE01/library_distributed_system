import 'package:flutter/material.dart';
import 'package:library_distributed_app/core/utils/local_storage_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_theme_mode.g.dart';

@riverpod
class AppThemeMode extends _$AppThemeMode {
  @override
  ThemeMode build() {
    final localThemeMode = localStorage.read<String>(
      LocalStorageKeys.themeMode,
    );
    return switch (localThemeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  void toggleBrightness() {
    final allModes = ThemeMode.values;
    final currentIndex = allModes.indexOf(state);
    state = allModes[(currentIndex + 1) % allModes.length];
    localStorage.write(LocalStorageKeys.themeMode, state.name);
  }
}
