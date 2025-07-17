import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1976D2),
        secondary: Color(0xFF03DAC6),
        surface: Color(0xFFF5F5F5),
        error: Color(0xFFD32F2F),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Color(0xFF333333),
        onError: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1976D2),
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
        ),
        bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF333333)),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF666666)),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 4,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFE3F2FD)),
        dataRowColor: WidgetStateProperty.all(Colors.white),
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF1976D2),
        ),
        dataTextStyle: const TextStyle(color: Color(0xFF333333)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF666666)),
        hintStyle: const TextStyle(color: Color(0xFF999999)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF42A5F5),
        secondary: Color(0xFF26A69A),
        surface: Color(0xFF121212),
        error: Color(0xFFCF6679),
        onPrimary: Color(0xFF121212),
        onSecondary: Colors.black,
        onSurface: Color(0xFFE0E0E0),
        onError: Color(0xFF121212),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF42A5F5),
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE0E0E0),
        ),
        bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFE0E0E0)),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFBDBDBD)),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF121212),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF42A5F5),
          foregroundColor: const Color(0xFF121212),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F1F1F),
        foregroundColor: Color(0xFFE0E0E0),
        elevation: 4,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE0E0E0),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color(0xFF1F1F1F),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(const Color(0xFF2C2C2C)),
        dataRowColor: WidgetStateProperty.all(const Color(0xFF1F1F1F)),
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF42A5F5),
        ),
        dataTextStyle: const TextStyle(color: Color(0xFFE0E0E0)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFFBDBDBD)),
        hintStyle: const TextStyle(color: Color(0xFF757575)),
      ),
    );
  }

  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color tableHeaderColor = Color(0xFFE3F2FD);
  static const Color darkWarningColor = Color(0xFFFFB74D);
  static const Color darkErrorColor = Color(0xFFCF6679);
  static const Color darkSuccessColor = Color(0xFF81C784);
  static const Color darkTableHeaderColor = Color(0xFF2C2C2C);

  static TextStyle get overdueTextStyle =>
      const TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.w500);

  static TextStyle get darkOverdueTextStyle =>
      const TextStyle(color: Color(0xFFCF6679), fontWeight: FontWeight.w500);

  static TextStyle get normalTextStyle =>
      const TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.normal);

  static TextStyle get darkNormalTextStyle =>
      const TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.normal);

  static TextStyle get headerTextStyle => const TextStyle(
    color: Color(0xFF1976D2),
    fontWeight: FontWeight.w600,
    fontSize: 18,
  );

  static TextStyle get darkHeaderTextStyle => const TextStyle(
    color: Color(0xFF42A5F5),
    fontWeight: FontWeight.w600,
    fontSize: 18,
  );
}
