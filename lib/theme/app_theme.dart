import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFE89A4C);
  static const Color backgroundColor = Color(0xFF2B2927);
  static const Color cardColor = Color(0xFF3E3B37);
  static const Color textColor = Color(0xFFFFFFFF);
  static const Color subtitleColor = Color(0xFFBBBBBB);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        background: backgroundColor,
        surface: cardColor,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: textColor,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: textColor,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: subtitleColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.inter(
          color: subtitleColor,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}