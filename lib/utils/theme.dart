import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryGreen = Color(0xFF2E7D32); // Dark Green
  static const Color secondaryGreen = Color(0xFF4CAF50); // Light Green
  static const Color accentGreen = Color(0xFF8BC34A); // Accent Green
  static const Color sandColor = Color(0xFFE6D2AD); // Sand/Bunker Color
  static const Color waterColor = Color(0xFF64B5F6); // Water Hazard Blue
  static const Color textDark = Color(0xFF212121); // Almost Black
  static const Color textLight = Color(0xFFF5F5F5); // Almost White
  static const Color dividerColor = Color(0xFFBDBDBD); // Gray

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryGreen,
    colorScheme: ColorScheme.light(
      primary: primaryGreen,
      secondary: secondaryGreen,
      surface: Colors.white,
      background: Colors.white,
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textDark,
      onBackground: textDark,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: secondaryGreen,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryGreen,
        side: const BorderSide(color: primaryGreen),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: primaryGreen, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    dividerTheme: const DividerThemeData(
      color: dividerColor,
      thickness: 1,
      space: 1,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: textDark,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        color: textDark,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: TextStyle(
        color: textDark,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: textDark,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        color: textDark,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: textDark,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: textDark,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: TextStyle(
        color: textDark,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(color: textDark),
      bodyMedium: TextStyle(color: textDark),
      bodySmall: TextStyle(color: textDark),
      labelLarge: TextStyle(
        color: textDark,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    primaryColor: primaryGreen,
    colorScheme: ColorScheme.dark(
      primary: primaryGreen,
      secondary: secondaryGreen,
      surface: const Color(0xFF212121),
      background: const Color(0xFF121212),
      error: Colors.red[300]!,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textLight,
      onBackground: textLight,
      onError: Colors.black,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: secondaryGreen,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryGreen,
        side: const BorderSide(color: primaryGreen),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: const Color(0xFF212121),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: primaryGreen, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: Colors.grey[800],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    dividerTheme: const DividerThemeData(
      color: dividerColor,
      thickness: 1,
      space: 1,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: textLight,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        color: textLight,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: TextStyle(
        color: textLight,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: textLight,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        color: textLight,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: textLight,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: textLight,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: TextStyle(
        color: textLight,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(color: textLight),
      bodyMedium: TextStyle(color: textLight),
      bodySmall: TextStyle(color: textLight),
      labelLarge: TextStyle(
        color: textLight,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
