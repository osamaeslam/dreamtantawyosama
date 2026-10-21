import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // هوية مجموعة الطنطاوي للتجارة والتوزيع
  static const Color primaryGold = Color(0xFFF59E0B);
  static const Color secondaryGold = Color(0xFFFBBF24);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color cardSlate = Color(0xFF1E293B);
  static const Color borderSlate = Color(0xFF334155);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color roseRed = Color(0xFFF43F5E);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color silver = Color(0xFF94A3B8);
  static const Color copper = Color(0xFFCD7F32);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color infoBlue = Color(0xFF3B82F6);

  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkText = Color(0xFFE2E8F0);
  static const Color darkTextMuted = Color(0xFF94A3B8);

  static const Color goldAccent = Color(0xFFE5B54F);
  static const Color goldLight = Color(0xFFFCD34D);
  static const Color goldDark = Color(0xFFB46414);

  static ThemeData lightTheme() {
    final textTheme = GoogleFonts.cairoTextTheme(
      ThemeData.light().textTheme,
    ).copyWith(
      bodyMedium: GoogleFonts.cairo(fontSize: 14, color: textDark),
      bodySmall: GoogleFonts.cairo(fontSize: 12, color: textMuted),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryGold,
      brightness: Brightness.light,
      primary: primaryGold,
      onPrimary: darkSlate,
      secondary: secondaryGold,
      surface: Colors.white,
      error: errorRed,
      onSurface: textDark,
      onSurfaceVariant: textMuted,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      primaryColor: primaryGold,
      scaffoldBackgroundColor: backgroundLight,
      textTheme: textTheme,
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGold, width: 2),
        ),
        labelStyle: GoogleFonts.cairo(color: textMuted),
        hintStyle: GoogleFonts.cairo(color: textMuted.withValues(alpha: 0.7)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: darkSlate,
          elevation: 3,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkSlate,
          side: const BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
      ),
      dividerColor: borderColor,
    );
  }

  static ThemeData darkTheme() {
    final textTheme = GoogleFonts.cairoTextTheme(
      ThemeData.dark().textTheme,
    ).copyWith(
      bodyMedium: GoogleFonts.cairo(fontSize: 14, color: darkText),
      bodySmall: GoogleFonts.cairo(fontSize: 12, color: darkTextMuted),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryGold,
      brightness: Brightness.dark,
      primary: primaryGold,
      onPrimary: darkSlate,
      secondary: secondaryGold,
      surface: darkCard,
      onSurface: darkText,
      onSurfaceVariant: darkTextMuted,
      error: errorRed,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      primaryColor: primaryGold,
      scaffoldBackgroundColor: darkBackground,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: darkCard,
        foregroundColor: darkText,
        elevation: 0,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: darkText,
        ),
        iconTheme: const IconThemeData(color: darkText),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGold, width: 2),
        ),
        labelStyle: GoogleFonts.cairo(color: darkTextMuted),
        hintStyle:
            GoogleFonts.cairo(color: darkTextMuted.withValues(alpha: 0.7)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: darkSlate,
          elevation: 3,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkText,
          side: const BorderSide(color: darkBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
      ),
      dividerColor: darkBorder,
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGold,
        foregroundColor: darkSlate,
      ),
      focusColor: primaryGold.withValues(alpha: 0.3),
      hoverColor: primaryGold.withValues(alpha: 0.2),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: primaryGold,
        labelColor: primaryGold,
        unselectedLabelColor: darkTextMuted,
      ),
    );
  }
}
