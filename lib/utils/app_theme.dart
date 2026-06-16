import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFFE07A5F); // Terracotta
  static const Color background = Color(0xFFFDFDFA); // Off-White
  static const Color textPrimary = Color(0xFF333333); // Slate Grey
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color success = Color(0xFF4CAF50);
  static const Color surface = Color(0xFFFFFFFF); // Surface White

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardColor: surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: surface,
        onPrimary: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: textPrimary),
        displayMedium: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: textPrimary),
        displaySmall: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textPrimary),
        headlineLarge: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: textPrimary),
        headlineMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textPrimary),
        headlineSmall: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textPrimary),
        titleSmall: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: GoogleFonts.dmSans(fontWeight: FontWeight.w400, color: textPrimary),
        bodyMedium: GoogleFonts.dmSans(fontWeight: FontWeight.w400, color: textPrimary),
        bodySmall: GoogleFonts.dmSans(fontWeight: FontWeight.w400, color: textSecondary),
        labelLarge: GoogleFonts.dmSans(fontWeight: FontWeight.w500, color: textPrimary),
        labelMedium: GoogleFonts.dmSans(fontWeight: FontWeight.w500, color: textPrimary),
        labelSmall: GoogleFonts.dmSans(fontWeight: FontWeight.w500, color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shadowColor: const Color(0x0F000000), // Very subtle shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: Color(0xFFEEEEEE)),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        labelStyle: GoogleFonts.dmSans(color: textSecondary),
        hintStyle: GoogleFonts.dmSans(color: textHint),
      ),
    );
  }
}

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
}
