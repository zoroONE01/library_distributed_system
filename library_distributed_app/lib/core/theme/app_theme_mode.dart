import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_theme_mode.g.dart';

@riverpod
class AppThemeMode extends _$AppThemeMode {
  @override
  ThemeMode build() {
    return ThemeMode.system;
  }

  void toggleBrightness() {
    final allModes = ThemeMode.values;
    final currentIndex = allModes.indexOf(state);
    state = allModes[(currentIndex + 1) % allModes.length];
  }
}
