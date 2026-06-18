import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors - Dark Mode
  static const Color darkBg = Color(0xFF0F0F12);
  static const Color darkCard = Color(0xFF18181F);
  static const Color darkPrimary = Color(0xFFD4AF37); // Warm Luxury Gold
  static const Color darkAccent = Color(0xFFB388FF); // Soft Violet
  static const Color darkTextPrimary = Color(0xFFF3F3F6);
  static const Color darkTextSecondary = Color(0xFF8E8E96);

  // Brand colors - Light Mode
  static const Color lightBg = Color(0xFFFAF9F6); // Soft Ivory/Alabaster
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF8C6B30); // Antique Gold/Bronze
  static const Color lightAccent = Color(0xFF7C4DFF); // Deep Indigo
  static const Color lightTextPrimary = Color(0xFF1E1E24);
  static const Color lightTextSecondary = Color(0xFF6E6E7A);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: darkPrimary,
      scaffoldBackgroundColor: darkBg,
      cardColor: darkCard,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkAccent,
        surface: darkCard,
        error: Color(0xFFCF6679),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: darkTextPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: darkTextSecondary,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: darkPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.white.withOpacity(0.06),
            width: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkCard,
        selectedItemColor: darkPrimary,
        unselectedItemColor: darkTextSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: lightPrimary,
      scaffoldBackgroundColor: lightBg,
      cardColor: lightCard,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: lightAccent,
        surface: lightCard,
        error: Color(0xFFB00020),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: lightTextPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: lightTextSecondary,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: lightPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.black.withOpacity(0.04),
            width: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightCard,
        selectedItemColor: lightPrimary,
        unselectedItemColor: lightTextSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
