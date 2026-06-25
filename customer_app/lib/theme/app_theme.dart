import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design-system source of truth for the ShipEast customer app.
///
/// Mirrors `design-system/shipeast/MASTER.md`. Brand primary is `#C8102E`
/// on a soft-white background. All tokens (colour, spacing, radius, shadow)
/// and the global [ThemeData] live here so every screen and shared widget
/// pulls from one place.
class AppTheme {
  AppTheme._();

  // ── Brand ────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFC8102E);
  static const Color primaryDark = Color(0xFFA00C24);
  static const Color primaryLight = Color(0xFFFFF0F2);
  static const Color primaryTint = Color(0xFFFFF8F9); // active input fill

  // ── Neutrals / surfaces ──────────────────────────────────────────────
  static const Color background = Color(0xFFF8F8FA); // soft white scaffold
  static const Color surface = Color(0xFFFFFFFF);
  static const Color dark = Color(0xFF111111);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textMuted = Color(0xFF888888);
  static const Color hint = Color(0xFF999999);
  static const Color gray = Color(0xFF666666);
  static const Color lightGray = Color(0xFFF2F2F2);

  // ── Inputs / borders ─────────────────────────────────────────────────
  static const Color inputBg = Color(0xFFF5F5F7);
  static const Color inputBorder = Color(0xFFEBEBEB);
  static const Color border = Color(0xFFEBEBEB);
  static const Color divider = Color(0xFFEFEFEF);
  static const Color inactive = Color(0xFFC0C0C0);

  // ── Semantic ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF97316);
  static const Color error = Color(0xFFDC2626);
  static const Color accent = Color(0xFFF97316);
  static const Color gold = Color(0xFFF5B301);

  // ── Spacing (4 / 8 rhythm) ───────────────────────────────────────────
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  // ── Radius ───────────────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 11;
  static const double radiusLg = 16;
  static const double radiusXl = 22;

  // ── Motion ───────────────────────────────────────────────────────────
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);

  // ── Elevation / shadows ──────────────────────────────────────────────
  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> shadowMd = [
    BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> shadowLg = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 10)),
  ];

  // ── Colour scheme ────────────────────────────────────────────────────
  static const ColorScheme _scheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: Colors.white,
    secondary: primary,
    onSecondary: Colors.white,
    tertiary: accent,
    onTertiary: Colors.white,
    error: error,
    onError: Colors.white,
    surface: surface,
    onSurface: textPrimary,
    surfaceContainerHighest: lightGray,
    outline: border,
  );

  /// Global text theme: Montserrat for display/headlines, Nunito for
  /// titles & labels, Inter for body — matching the existing screens.
  static TextTheme get _textTheme {
    final body = GoogleFonts.interTextTheme();
    return body.copyWith(
      displayLarge: GoogleFonts.montserrat(
          fontSize: 28, fontWeight: FontWeight.w900, color: textPrimary),
      displayMedium: GoogleFonts.montserrat(
          fontSize: 24, fontWeight: FontWeight.w900, color: textPrimary),
      headlineSmall: GoogleFonts.montserrat(
          fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
      titleLarge: GoogleFonts.nunito(
          fontSize: 16, fontWeight: FontWeight.w900, color: textPrimary),
      titleMedium: GoogleFonts.nunito(
          fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary),
      titleSmall: GoogleFonts.nunito(
          fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
      bodyLarge: GoogleFonts.inter(fontSize: 14, color: textPrimary),
      bodyMedium: GoogleFonts.inter(fontSize: 13, color: textPrimary),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: textSecondary),
      labelLarge: GoogleFonts.nunito(
          fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
      labelMedium: GoogleFonts.nunito(
          fontSize: 11, fontWeight: FontWeight.w800, color: textSecondary),
    );
  }

  static ThemeData get theme {
    final t = ThemeData(
      useMaterial3: true,
      colorScheme: _scheme,
      scaffoldBackgroundColor: background,
      textTheme: _textTheme,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.montserrat(
            fontSize: 16, fontWeight: FontWeight.w900, color: textPrimary),
        iconTheme: const IconThemeData(color: Color(0xFF444444), size: 20),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd)),
          textStyle:
              GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w900),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd)),
          textStyle:
              GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w900),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle:
              GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        hintStyle: GoogleFonts.inter(fontSize: 13, color: hint),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: _inputBorder(border),
        enabledBorder: _inputBorder(border),
        focusedBorder: _inputBorder(primary, width: 1.5),
        errorBorder: _inputBorder(error),
        focusedErrorBorder: _inputBorder(error, width: 1.5),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg)),
      ),
      dividerTheme: const DividerThemeData(
          color: divider, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: lightGray,
        selectedColor: primary,
        labelStyle:
            GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl)),
        side: BorderSide.none,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primary,
        behavior: SnackBarBehavior.floating,
        contentTextStyle:
            GoogleFonts.nunito(fontWeight: FontWeight.w700, color: Colors.white),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm + 2)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: inactive,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
    return t;
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1.5}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMd),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
