import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_theme_mode.g.dart';

@riverpod
class AppThemeMode extends _$AppThemeMode {
  @override
  ThemeMode build() {
    return ThemeMode.dark;
  }

  void toggleBrightness() {
    // Toggle between light and dark mode
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}