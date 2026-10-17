import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // هوية مجموعة الطنطاوي للتجارة والتوزيع
  static const Color primaryGold = Color(0xFFF59E0B); // Amber 500
  static const Color secondaryGold = Color(0xFFFBBF24); // Amber 400
  static const Color darkSlate = Color(0xFF0F172A); // Slate 900
  static const Color cardSlate = Color(0xFF1E293B); // Slate 800
  static const Color borderSlate = Color(0xFF334155); // Slate 700
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color roseRed = Color(0xFFF43F5E);
  static const Color errorRed = Color(0xFFEF4444); // Red 500
  static const Color warningAmber = Color(0xFFF59E0B); // Amber 500
  static const Color silver = Color(0xFF94A3B8); // Slate 400
  static const Color copper = Color(0xFFCD7F32); // Copper
  static const Color borderColor = Color(0xFFE2E8F0); // Slate 200
  static const Color infoBlue = Color(0xFF3B82F6);

  // === Dark theme palette ===
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkText = Color(0xE0FFFFFF);
  static const Color darkTextMuted = Color(0xFF94A3B8);
  static const Color darkGoldGlow = Color(0xFFFCD34D);

  static ThemeData lightTheme() {
    final baseFont = GoogleFonts.cairoTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryGold,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGold,
        primary: primaryGold,
        secondary: secondaryGold,
        surface: Colors.white,
        background: backgroundLight,
      ),
      textTheme: GoogleFonts.cairoTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: darkSlate,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryGold,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.dark(
        primary: primaryGold,
        secondary: secondaryGold,
        surface: darkCard,
        background: darkBackground,
        onBackground: darkText,
        onSurface: darkText,
      ),
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: darkCard,
        foregroundColor: darkText,
        elevation: 0,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: secondaryGold,
        ),
        iconTheme: const IconThemeData(color: darkText),
      ),
      cardTheme: CardTheme(
        color: darkCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: darkBorder),
        ),
      ),
    );
  }
}
