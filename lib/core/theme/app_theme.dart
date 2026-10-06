// ============================================================
// TEMA APLIKASI (LIGHT & DARK)
// Semua warna brand terpusat di sini agar konsisten:
//   seed ungu-indigo (#4F46E5 / #7C4DFF)
// ============================================================
import 'package:flutter/material.dart';

/// Warna brand utama aplikasi (dipakai juga di grafik, chip, dll).
const Color kBrandColor = Color(0xFF4F46E5); // indigo
const Color kBrandAccent = Color(0xFF7C4DFF); // ungu

class AppTheme {
  AppTheme._();

  /// Radius sudut standar (kartu, dialog, input).
  static const double radius = 16;

  // ================= TEMA TERANG =================
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: kBrandColor,
      brightness: Brightness.light,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF6F7FB),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  // ================= TEMA GELAP =================
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: kBrandAccent,
      brightness: Brightness.dark,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFF0F1220),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1A1E2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F1220),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  // ================= DASAR BERSAMA =================
  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // ---- Input field ----
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: kBrandColor, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      // ---- Chip ----
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide.none,
      ),
      // ---- FAB ----
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 2,
      ),
      // ---- Navigasi bawah ----
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.primary.withValues(alpha: 0.15),
        elevation: 0,
      ),
      // ---- Dialog ----
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
