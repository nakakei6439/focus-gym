import 'package:flutter/material.dart';

class AppTheme {
  // ナチュラル グリーン・クリーム パレット（女性向け）
  static const Color primary = Color(0xFF5C9E7A);        // ソフトグリーン
  static const Color primaryLight = Color(0xFF7DB896);   // ライトグリーン
  static const Color background = Color(0xFFFAFAF5);     // クリーム白
  static const Color surface = Color(0xFFF0F4EE);        // ライトグリーンサーフェス
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF6B7B6F);
  static const Color accent = Color(0xFFE8A87C);         // ピーチ

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        surface: surface,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: background,
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary),
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 18, color: textPrimary, height: 1.6),
        bodyMedium: TextStyle(fontSize: 16, color: textPrimary, height: 1.5),
        bodySmall: TextStyle(fontSize: 14, color: textSecondary, height: 1.5),
        labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shadowColor: Color(0x1A5C9E7A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFAFAF5),
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 13),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
