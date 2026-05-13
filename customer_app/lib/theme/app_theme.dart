import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFC8102E);
  static const Color primaryLight = Color(0xFFFFF0F2);
  static const Color dark = Color(0xFF111111);
  static const Color gray = Color(0xFF666666);
  static const Color lightGray = Color(0xFFF2F2F2);
  static const Color inputBg = Color(0xFFF5F5F7);
  static const Color inputBorder = Color(0xFFEBEBEB);

  static ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        useMaterial3: true,
      );
}
