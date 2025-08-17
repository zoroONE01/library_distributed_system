import 'package:flutter/material.dart';

extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  Brightness get brightness => theme.brightness;

  TextStyle get headlineLarge =>
      textTheme.headlineLarge ?? const TextStyle(fontSize: 28);
  TextStyle get headlineMedium =>
      textTheme.headlineMedium ?? const TextStyle(fontSize: 24);
  TextStyle get headlineSmall =>
      textTheme.headlineSmall ?? const TextStyle(fontSize: 20);
  TextStyle get titleLarge =>
      textTheme.titleLarge ?? const TextStyle(fontSize: 22);
  TextStyle get titleMedium =>
      textTheme.titleMedium ?? const TextStyle(fontSize: 16);
  TextStyle get titleSmall =>
      textTheme.titleSmall ?? const TextStyle(fontSize: 14);
  TextStyle get bodyLarge =>
      textTheme.bodyLarge ?? const TextStyle(fontSize: 16);
  TextStyle get bodyMedium =>
      textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
  TextStyle get bodySmall =>
      textTheme.bodySmall ?? const TextStyle(fontSize: 12);
  TextStyle get labelLarge =>
      textTheme.labelLarge ?? const TextStyle(fontSize: 14);
  TextStyle get labelMedium =>
      textTheme.labelMedium ?? const TextStyle(fontSize: 12);

  Color get primaryColor => colorScheme.primary;
  Color get primaryVariant => colorScheme.primaryContainer;
  Color get primaryContainer => colorScheme.primaryContainer;
  Color get onPrimaryContainer => colorScheme.onPrimaryContainer;
  Color get secondaryColor => colorScheme.secondary;
  Color get secondaryVariant => colorScheme.secondaryContainer;
  Color get surfaceColor => colorScheme.surface;
  Color get surfaceContainer => colorScheme.surfaceContainer;
  Color get surfaceContainerHighest => colorScheme.surfaceContainerHighest;
  Color get errorColor => colorScheme.error;
  Color get errorContainer => colorScheme.errorContainer;
  Color get onErrorContainer => colorScheme.onErrorContainer;
  Color get onPrimary => colorScheme.onPrimary;
  Color get onSecondary => colorScheme.onSecondary;
  Color get onSurface => colorScheme.onSurface;
  Color get onSurfaceVariant => colorScheme.onSurfaceVariant;
}
