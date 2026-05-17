import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// Grow Openings Color Palette
// ============================================================
class AppColors {
  // Shared
  static const Color primary = Color(0xFFB3E257);        // Lime Green accent
  static const Color primaryDark = Color(0xFF8BB538);    // Darker green
  static const Color boardLight = Color(0xFFF3EEDF);
  static const Color boardDark = Color(0xFF9E846A);

  // Light Mode
  static const Color lightBackground = Color(0xFFF5F3ED);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF3E3A35);
  static const Color lightTextSecondary = Color(0xFF8D867D);
  static const Color lightBorder = Color(0xFFE5E0D8);
  static const Color lightHeader = Color(0xFF2A2118);   // Dark brown for header

  // Dark Mode
  static const Color darkBackground = Color(0xFF2A2522);
  static const Color darkSurface = Color(0xFF38322E);
  static const Color darkTextPrimary = Color(0xFFF5F3ED);
  static const Color darkTextSecondary = Color(0xFFA39B92);
  static const Color darkBorder = Color(0xFF4A433D);

  // Helper method to get adaptive colors
  static Color bg(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;
  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light ? lightBorder : darkBorder;
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light ? lightTextPrimary : darkTextPrimary;
  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light ? lightTextSecondary : darkTextSecondary;
}

// ============================================================
// Theme Definitions
// ============================================================
class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryDark,
        surface: AppColors.lightSurface,
        background: AppColors.lightBackground,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(color: AppColors.lightTextPrimary, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.outfit(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.outfit(color: AppColors.lightTextPrimary),
        bodyMedium: GoogleFonts.outfit(color: AppColors.lightTextSecondary),
        labelSmall: GoogleFonts.outfit(color: AppColors.lightTextPrimary, letterSpacing: 1.2, fontWeight: FontWeight.bold),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightHeader,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.lightBorder),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.lightTextSecondary),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryDark,
        surface: AppColors.darkSurface,
        background: AppColors.darkBackground,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.outfit(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.outfit(color: AppColors.darkTextPrimary),
        bodyMedium: GoogleFonts.outfit(color: AppColors.darkTextSecondary),
        labelSmall: GoogleFonts.outfit(color: AppColors.darkTextPrimary, letterSpacing: 1.2, fontWeight: FontWeight.bold),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.darkBorder),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.darkTextSecondary),
      ),
    );
  }
}