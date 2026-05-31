import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFFC8102E);
  static const Color background = Colors.white;
  static const Color surfaceGrey = Color(0xFFF5F5F7);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF111111);
  static const Color textMid = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
  static const Color success = Color(0xFF16A34A);
  static const Color divider = Color(0xFFEFEFEF);

  // Heading styles - Montserrat Black (weight 900)
  static TextStyle headingXL({Color color = textDark}) => GoogleFonts.montserrat(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: color,
      );

  static TextStyle headingLG({Color color = textDark}) => GoogleFonts.montserrat(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: color,
      );

  static TextStyle headingMD({Color color = textDark}) => GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: color,
      );

  static TextStyle headingSM({Color color = textDark}) => GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: color,
      );

  // Body styles - Inter
  static TextStyle body({Color color = textDark, double fontSize = 14}) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodySmall({Color color = textMid}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
      );

  // Button styles - Nunito Black (weight 900)
  static TextStyle buttonLG({Color color = Colors.white}) => GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.w900,
        color: color,
      );

  static TextStyle buttonSM({Color color = Colors.white}) => GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: color,
      );

  // Splash style - Dancing Script
  static TextStyle splash({Color color = Colors.white}) => GoogleFonts.dancingScript(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color,
        fontStyle: FontStyle.italic,
      );

  // Input decoration helper
  static InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: textLight, size: 20),
      labelStyle: GoogleFonts.inter(color: textMid, fontSize: 14),
      filled: true,
      fillColor: surfaceGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: divider, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  static ThemeData buildTheme() {
    return ThemeData(
      useMaterial3: false,
      primaryColor: primary,
      primarySwatch: MaterialColor(primary.value, const {
        50: Color(0xFFFFEBEE),
        100: Color(0xFFFFCDD2),
        200: Color(0xFFEF9A9A),
        300: Color(0xFFE57373),
        400: Color(0xFFEF5350),
        500: Color(0xFFC8102E),
        600: Color(0xFFB00D28),
        700: Color(0xFF950A22),
        800: Color(0xFF7A081C),
        900: Color(0xFF5F0615),
      }),
      scaffoldBackgroundColor: background,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: textDark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primary,
        surface: background,
      ),
    );
  }
}
