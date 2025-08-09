import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light theme colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color accentColor = Color(0xFF03DAC6);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFE57373);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);

  // Dark theme colors
  static const Color darkPrimaryBlue = Color(0xFF64B5F6);
  static const Color darkPrimaryDark = Color(0xFF42A5F5);
  static const Color darkAccentColor = Color(0xFF4DD0E1);
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkErrorColor = Color(0xFFCF6679);
  static const Color darkWarningColor = Color(0xFFFFB74D);
  static const Color darkSuccessColor = Color(0xFF81C784);

  // Light theme text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Dark theme text colors
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFFBDBDBD);
  static const Color darkTextOnPrimary = Color(0xFF000000);

  // Border and divider colors
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color dividerColor = Color(0xFFBDBDBD);
  static const Color darkBorderColor = Color(0xFF424242);
  static const Color darkDividerColor = Color(0xFF616161);

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
        secondary: accentColor,
        surface: surfaceColor,
        error: errorColor,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: textOnPrimary,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textOnPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      textTheme: _buildTextTheme(textPrimary, textSecondary),
      elevatedButtonTheme: _buildElevatedButtonTheme(
        primaryBlue,
        textOnPrimary,
      ),
      outlinedButtonTheme: _buildOutlinedButtonTheme(primaryBlue),
      cardTheme: _buildCardTheme(surfaceColor),
      dataTableTheme: _buildDataTableTheme(primaryBlue, textPrimary),
      inputDecorationTheme: _buildInputDecorationTheme(
        borderColor,
        primaryBlue,
        errorColor,
        surfaceColor,
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 16,
      ),
      scaffoldBackgroundColor: backgroundColor,
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkPrimaryBlue,
        brightness: Brightness.dark,
        primary: darkPrimaryBlue,
        secondary: darkAccentColor,
        surface: darkSurfaceColor,
        error: darkErrorColor,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurfaceColor,
        foregroundColor: darkTextPrimary,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      textTheme: _buildTextTheme(darkTextPrimary, darkTextSecondary),
      elevatedButtonTheme: _buildElevatedButtonTheme(
        darkPrimaryBlue,
        darkTextOnPrimary,
      ),
      outlinedButtonTheme: _buildOutlinedButtonTheme(darkPrimaryBlue),
      cardTheme: _buildCardTheme(darkSurfaceColor),
      dataTableTheme: _buildDataTableTheme(darkPrimaryBlue, darkTextPrimary),
      inputDecorationTheme: _buildInputDecorationTheme(
        darkBorderColor,
        darkPrimaryBlue,
        darkErrorColor,
        darkSurfaceColor,
      ),
      dividerTheme: const DividerThemeData(
        color: darkDividerColor,
        thickness: 1,
        space: 16,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
    );
  }

  // Helper methods to build theme components
  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: primaryColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: primaryColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: secondaryColor,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primaryColor,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
      ),
    )..apply(
      fontFamily: GoogleFonts.roboto().fontFamily,
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(
    Color backgroundColor,
    Color foregroundColor,
  ) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(Color primaryColor) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static CardThemeData _buildCardTheme(Color surfaceColor) {
    return CardThemeData(
      color: surfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(8),
    );
  }

  static DataTableThemeData _buildDataTableTheme(
    Color primaryColor,
    Color textColor,
  ) {
    return DataTableThemeData(
      headingRowColor: WidgetStateProperty.all(
        primaryColor.withValues(alpha: 0.1),
      ),
      dataRowColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor.withValues(alpha: 0.2);
        }
        return null;
      }),
      headingTextStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      dataTextStyle: TextStyle(color: textColor),
      dividerThickness: 1,
      columnSpacing: 20,
      horizontalMargin: 16,
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(
    Color borderColor,
    Color focusColor,
    Color errorColor,
    Color fillColor,
  ) {
    return InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: focusColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: errorColor),
      ),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  // Context-aware text styles that adapt to theme
  static TextStyle overdueTextStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      color: isDark ? darkErrorColor : errorColor,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle warningTextStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      color: isDark ? darkWarningColor : warningColor,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle successTextStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      color: isDark ? darkSuccessColor : successColor,
      fontWeight: FontWeight.w500,
    );
  }

  // Context-aware decorations
  static BoxDecoration overdueCardDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorColor = isDark ? darkErrorColor : AppTheme.errorColor;

    return BoxDecoration(
      color: errorColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: errorColor.withValues(alpha: 0.3)),
    );
  }

  static BoxDecoration formContainerDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      color: isDark ? darkSurfaceColor : surfaceColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
          spreadRadius: 1,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
